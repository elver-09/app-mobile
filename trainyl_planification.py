from odoo import models, fields, api
from odoo.exceptions import UserError
from odoo.tools.misc import format_date
from datetime import datetime, time
import logging
_logger = logging.getLogger(__name__)
class TrainylPlanificationExtra(models.Model):
    _name = 'trainyl.planification.extra'
    _description = 'Planificación'

    name = fields.Char(string='Secuencia', copy=False, readonly=True)
    fecha_planificacion = fields.Date(string='Fecha de planificación', required=True, default=fields.Date.context_today)
    planificado_por = fields.Many2one('res.users', string='Planificado por', default=lambda self: self.env.user, required=True)
    service_type_id = fields.Many2one('trainyl.service.type', string='Tipo de Servicio', required=True)
    
    ruta_ids = fields.One2many('trainyl.routes.extra','planificacion_id', string='Rutas')
    state = fields.Selection([
        ('borrador', 'Borrador'),
        ('en_planificacion', 'En Planificación'),
        ('confirmado', 'Confirmado'),
        ('cancelado', 'Cancelado')
    ], string='Estado', default='borrador', required=True)
    
    @api.model
    def create(self, vals):
        _logger.info("Creando Planificación - Valor recibido en fecha_planificacion: %s", vals.get('fecha_planificacion'))
        # Asignar secuencia sólo si no viene nombre; usa la secuencia sequence_trainyl_planification_extra
        if not vals.get('name'):
            vals['name'] = self.env['ir.sequence'].next_by_code('trainyl.planification.extra') or 'New'
        return super(TrainylPlanificationExtra, self).create(vals)

    def action_generar_automaticamente(self):
        self.ensure_one()
        
        # 🔴 VALIDACIÓN: Verificar que service_type_id esté configurado
        if not self.service_type_id:
            raise UserError("El campo 'Tipo de Servicio' es obligatorio. Por favor, seleccione un tipo de servicio antes de generar automáticamente las rutas.")
        
        _logger.info("Ejecutando generación automática - Fecha de planificación: %s", self.fecha_planificacion)
        
        # 1. Usamos self.fecha_planificacion en lugar de self.date
        orders = self.env['trainyl.order'].search([
            ('delivery_date', '=', self.fecha_planificacion),
            ('order_type_id', '=', self.service_type_id.id),
            ('route_id', '=', False),
            ('driver_id', '=', False),
            ('zone_id', '!=', False)
        ])

        if not orders:
            # Diagnóstico detallado para el usuario
            total_orders = self.env['trainyl.order'].search_count([('delivery_date', '=', self.fecha_planificacion), ('order_type_id', '=', self.service_type_id.id)])
            if total_orders == 0:
                raise UserError("No existen órdenes registradas para la fecha %s con el tipo de servicio %s." % (self.fecha_planificacion, self.service_type_id.name))
            
            pending_orders = self.env['trainyl.order'].search_count([('delivery_date', '=', self.fecha_planificacion), ('order_type_id', '=', self.service_type_id.id), ('route_id', '=', False)])
            if pending_orders == 0:
                raise UserError("Todas las órdenes de la fecha %s con el tipo de servicio %s ya tienen una ruta asignada." % (self.fecha_planificacion, self.service_type_id.name))
            
            raise UserError("Se encontraron %s órdenes pendientes para la fecha %s con el tipo de servicio %s, pero ninguna tiene una Zona asignada. Por favor asigne una Zona a las órdenes." % (pending_orders, self.fecha_planificacion, self.service_type_id.name))

        orders_by_zone = {}
        for order in orders:
            if order.zone_id.id not in orders_by_zone:
                orders_by_zone[order.zone_id.id] = []
            orders_by_zone[order.zone_id.id].append(order)
            
        for zone_id, zone_orders in orders_by_zone.items():
            zona_obj = self.env['trainyl.zone'].browse(zone_id)

            # 🔍 BUSCAR RUTA EXISTENTE
            route = self.env['trainyl.routes.extra'].search([
                ('zone_id', '=', zone_id),
                ('ruta_date', '=', self.fecha_planificacion),
            ], limit=1)

            # Si encontramos una ruta existente (quizás huérfana o de otra planificación), la asignamos a esta planificación
            if route and route.planificacion_id != self:
                route.planificacion_id = self.id

            # 🆕 CREAR SOLO SI NO EXISTE
            if not route:
                route = self.env['trainyl.routes.extra'].create({
                    'name': f'Ruta {zona_obj.name}',
                    'planificacion_id': self.id,
                    'zone_id': zone_id,
                    'ruta_date': self.fecha_planificacion,
                })

            # 🔗 OBTENER TODAS LAS ÓRDENES DE LA RUTA (EXISTENTES + NUEVAS)
            # Buscar órdenes ya asignadas a esta ruta
            existing_orders = self.env['trainyl.order'].search([
                ('route_id', '=', route.id)
            ])
            
            # Combinar órdenes existentes con las nuevas (sin duplicados)
            all_orders = existing_orders | self.env['trainyl.order'].browse([o.id for o in zone_orders])
            all_orders = all_orders.filtered(lambda o: o.zone_id.id == zone_id)  # Asegurar misma zona
            
            _logger.info(f"Ruta {route.name}: {len(existing_orders)} órdenes existentes + {len(zone_orders)} nuevas = {len(all_orders)} total")
            
            # 🔗 ORDENAR TODAS LAS ÓRDENES POR DISTANCIA DESDE EL PICKUP_ORIGIN
            if self.service_type_id.pickup_origin_id:
                pickup = self.service_type_id.pickup_origin_id
                pickup_lat = float(pickup.latitude) if pickup.latitude else 0
                pickup_lon = float(pickup.longitude) if pickup.longitude else 0
                
                # Calcular distancia para cada orden y ordenarlas
                def calculate_order_distance(order):
                    if order.latitude and order.longitude:
                        order_lat = float(order.latitude)
                        order_lon = float(order.longitude)
                        return self._calculate_distance_haversine(pickup_lat, pickup_lon, order_lat, order_lon)
                    return float('inf')  # Ordenar al final las órdenes sin coordenadas
                
                # Ordenar TODAS las órdenes (existentes + nuevas) por distancia
                sorted_orders = sorted(all_orders, key=calculate_order_distance)
                
                # Actualizar TODAS las órdenes con nueva secuencia
                for sequence, order in enumerate(sorted_orders, start=1):
                    distance = calculate_order_distance(order)
                    order.write({
                        'route_id': route.id,
                        'route_sequence': sequence,
                        'distance_from_pickup': distance if distance != float('inf') else 0,
                        'expected_status': 'in_planification'
                    })
                    # 🔥 CREAR LOG MÓVIL AL PLANIFICAR
                    order._create_mobile_log(
                        message=f"Orden planificada automáticamente en ruta '{route.name}' - Secuencia: {sequence}, Distancia: {distance:.2f} km - Estado cambiado a EN PLANIFICACIÓN",
                        driver_id=route.driver_id.id if route.driver_id else False,
                        vehicle_id=route.fleet_id.id if route.fleet_id else False,
                        expected_status='in_planification'
                    )
                    _logger.info(f"Orden {order.order_number} actualizada en ruta con secuencia {sequence}, distancia: {distance} km, estado: in_planification")
            else:
                # Si no hay pickup_origin, solo asignar ruta a las nuevas
                for order in zone_orders:
                    order.write({
                        'route_id': route.id,
                        'expected_status': 'in_planification'
                    })
                    # 🔥 CREAR LOG MÓVIL AL PLANIFICAR (sin distancia)
                    order._create_mobile_log(
                        message=f"Orden planificada automáticamente en ruta '{route.name}' - Estado cambiado a EN PLANIFICACIÓN",
                        driver_id=route.driver_id.id if route.driver_id else False,
                        vehicle_id=route.fleet_id.id if route.fleet_id else False,
                        expected_status='in_planification'
                    )

        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': 'Éxito',
                'message': 'Rutas generadas correctamente ordenadas por latitud y longitud',
                'type': 'success',
            }
        }

    def _calculate_distance_haversine(self, lat1, lon1, lat2, lon2):
        """
        Calcula la distancia en kilómetros entre dos puntos usando la fórmula Haversine.
        Parámetros:
            lat1, lon1: Latitud y longitud del punto de recojo (en grados decimales)
            lat2, lon2: Latitud y longitud de la orden/entrega (en grados decimales)
        Retorna: Distancia en kilómetros
        """
        from math import radians, cos, sin, asin, sqrt
        
        try:
            lat1 = float(lat1) if lat1 else 0
            lon1 = float(lon1) if lon1 else 0
            lat2 = float(lat2) if lat2 else 0
            lon2 = float(lon2) if lon2 else 0
            
            if (lat1 == 0 and lon1 == 0) or (lat2 == 0 and lon2 == 0):
                return 0
            
            R = 6371  # Radio de la Tierra en kilómetros
            
            lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
            dlat = lat2 - lat1
            dlon = lon2 - lon1
            
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            distance = R * c
            
            return round(distance, 2)
        except (ValueError, TypeError):
            _logger.warning(f"Error calculando distancia con coordenadas: {lat1}, {lon1}, {lat2}, {lon2}")
            return 0
    def action_confirmar(self):
        pass
    def action_ver_ordenes_sin_asignar(self):
        pass

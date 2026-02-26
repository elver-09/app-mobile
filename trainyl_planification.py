from odoo import models, fields, api
from odoo.exceptions import UserError
from odoo.tools.misc import format_date
from datetime import datetime, time
import logging
_logger = logging.getLogger(__name__)
class TrainylPlanificationExtra(models.Model):
    _name = 'trainyl.planification.extra'
    _description = 'Planificación'

    name = fields.Char(string='Secuencia', copy=False, readonly=True, default='New')
    fecha_planificacion = fields.Date(string='Fecha de planificación', required=True, default=fields.Date.context_today)
    fecha_planificacion_original = fields.Date(string='Fecha de planificación original', readonly=True, copy=False)
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
        # Guardar la fecha original de planificación (inmutable)
        if not vals.get('fecha_planificacion_original') and vals.get('fecha_planificacion'):
            vals['fecha_planificacion_original'] = vals['fecha_planificacion']
        return super(TrainylPlanificationExtra, self).create(vals)

    def action_generar_automaticamente(self):
        self.ensure_one()
        
        # 🔴 VALIDACIÓN: Verificar que la fecha no haya sido modificada
        if self.fecha_planificacion_original and self.fecha_planificacion != self.fecha_planificacion_original:
            raise UserError("No se puede generar planificación automática porque la fecha de planificación ha sido modificada.\n\nFecha original: %s\nFecha actual: %s\n\nEsta planificación fue creada para la fecha %s. Por favor, cree una nueva planificación si desea planificar para una fecha diferente." % (self.fecha_planificacion_original, self.fecha_planificacion, self.fecha_planificacion_original))
        
        # 🔴 VALIDACIÓN: Verificar que service_type_id esté configurado
        if not self.service_type_id:
            raise UserError("El campo 'Tipo de Servicio' es obligatorio. Por favor, seleccione un tipo de servicio antes de generar automáticamente las rutas.")
        
        _logger.info("Ejecutando generación automática - Fecha de planificación: %s", self.fecha_planificacion)
        
        all_orders = self.env['trainyl.order'].search([
            ('delivery_date', '=', self.fecha_planificacion),
            ('order_type_id', '=', self.service_type_id.id),
            ('route_id', '=', False),
            ('driver_id', '=', False),
            ('expected_status', '=', 'pending')
        ])

        # Separar órdenes con zona y sin zona
        orders_with_zone = [o for o in all_orders if o.zone_id]
        orders_without_zone = [o for o in all_orders if not o.zone_id]

        # Log para órdenes sin zona
        if orders_without_zone:
            ordenes_sin_zona = ', '.join([f"{order.order_number}(ID:{order.id})" for order in orders_without_zone])
            _logger.info(f"Órdenes sin zona asignada al planificar: {ordenes_sin_zona}")
            for order in orders_without_zone:
                _logger.warning(f"Orden sin zona asignada: {order.order_number} (ID: {order.id})")
                order._create_mobile_log(
                    message=f"Orden sin zona asignada al intentar planificar automáticamente. Fecha: {self.fecha_planificacion}, Tipo de servicio: {self.service_type_id.name}",
                    expected_status='pending'
                )

        if not orders_with_zone:
            total_orders = len(all_orders)
            if total_orders == 0:
                raise UserError("No existen órdenes registradas para la fecha %s con el tipo de servicio %s." % (self.fecha_planificacion, self.service_type_id.name))
            raise UserError("Todas las órdenes pendientes para la fecha %s y tipo de servicio %s están sin zona asignada. Se omitieron en la planificación automática." % (self.fecha_planificacion, self.service_type_id.name))

        # Agrupar órdenes por zona
        orders_by_zone = {}
        for order in orders_with_zone:
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

            _logger.info(f"Ruta {route.name}: planificando {len(zone_orders)} órdenes nuevas en estado PENDING")

            # 🔗 ORDENAR ÓRDENES PENDING POR DISTANCIA DESDE EL PICKUP_ORIGIN
            if self.service_type_id.pickup_origin_id:
                pickup = self.service_type_id.pickup_origin_id
                pickup_lat = float(pickup.latitude) if pickup.latitude else 0
                pickup_lon = float(pickup.longitude) if pickup.longitude else 0

                def calculate_order_distance(order):
                    if order.latitude and order.longitude:
                        order_lat = float(order.latitude)
                        order_lon = float(order.longitude)
                        return self._calculate_distance_haversine(pickup_lat, pickup_lon, order_lat, order_lon)
                    return float('inf')

                sorted_orders = sorted(zone_orders, key=calculate_order_distance)

                last_sequence = self.env['trainyl.order'].search_read(
                    [('route_id', '=', route.id)],
                    ['route_sequence'],
                    order='route_sequence desc',
                    limit=1
                )
                next_sequence = last_sequence[0]['route_sequence'] + 1 if last_sequence and last_sequence[0]['route_sequence'] else 1

                for order in sorted_orders:
                    distance = calculate_order_distance(order)
                    order.write({
                        'route_id': route.id,
                        'route_sequence': next_sequence,
                        'distance_from_pickup': distance if distance != float('inf') else 0,
                        'expected_status': 'in_planification'
                    })
                    order._create_mobile_log(
                        message=f"Orden planificada automáticamente en ruta '{route.name}' - Secuencia: {next_sequence}, Distancia: {distance:.2f} km - Estado cambiado a EN PLANIFICACIÓN",
                        driver_id=route.driver_id.id if route.driver_id else False,
                        vehicle_id=route.fleet_id.id if route.fleet_id else False,
                        expected_status='in_planification'
                    )
                    _logger.info(f"Orden {order.order_number} actualizada en ruta con secuencia {next_sequence}, distancia: {distance} km, estado: in_planification")
                    next_sequence += 1
            else:
                for order in zone_orders:
                    order.write({
                        'route_id': route.id,
                        'expected_status': 'in_planification'
                    })
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
                'message': 'Rutas generadas correctamente. Órdenes sin zona fueron omitidas y registradas en log.',
                'type': 'success',
            }
        }

    def _calculate_distance_haversine(self, lat1, lon1, lat2, lon2):
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
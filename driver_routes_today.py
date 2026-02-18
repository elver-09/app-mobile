from odoo import http
from odoo.http import request
from datetime import date

class DriverRouteController(http.Controller):

    @http.route('/driver/routes/today', type='json', auth='public', csrf=False)
    def driver_routes_today(self):
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        today = date.today()
        
        routes = request.env['trainyl.routes.extra'].sudo().search([
            ('driver_id', '=', employee.id),
            ('ruta_date', '=', today),
        ])

        data = []
        for r in routes:
            data.append({
                'id': r.id,
                'name': r.name or '',
                'zone': r.zone_id.name if r.zone_id else '',
                'fleet': r.fleet_id.license_plate if r.fleet_id else '',
                'ruta_date': str(r.ruta_date) if r.ruta_date else '',
                'orders_qty': len(r.order_ids),
                'state_route': r.state_route or 'to_validate',
            })

        return {'success': True, 'routes': data}

    @http.route('/driver/routes/orders/<int:route_id>', type='json', auth='public', csrf=False)
    def driver_routes_orders(self, route_id):
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        route = request.env['trainyl.routes.extra'].sudo().search([
            ('id', '=', route_id),
            ('driver_id', '=', employee.id),
        ], limit=1)
        
        if not route:
            return {'success': False, 'error': 'Ruta no encontrada'}
        
        route_start_address = None
        route_start_latitude = None
        route_start_longitude = None
        origin_lat = None
        origin_lon = None
        
        for order in route.order_ids:
            if order.order_type_id and order.order_type_id.pickup_origin_id:
                pickup_origin = order.order_type_id.pickup_origin_id
                route_start_address = pickup_origin.address or 'Origen'
                origin_lat = float(pickup_origin.latitude) if pickup_origin.latitude else None
                origin_lon = float(pickup_origin.longitude) if pickup_origin.longitude else None
                route_start_latitude = origin_lat
                route_start_longitude = origin_lon
                break
        
        fleet_type = route.fleet_id.fleet_type_id.name if route.fleet_id and route.fleet_id.fleet_type_id else 'Vehículo'
        fleet_license = route.fleet_id.license_plate if route.fleet_id else 'N/A'
        
        orders_with_data = []
        
        # Traer TODAS las órdenes de la ruta (in_planification e in_transport)
        for order in route.order_ids:
            products = []
            for line in order.order_line_ids:
                if line.product_des:
                    products.append(line.product_des)
            
            product_description = ', '.join(products) if products else 'N/A'
            status = order.expected_status or 'in_planification'
            
            orders_with_data.append({
                'id': order.id,
                'order_number': order.order_number or order.display_name or '',
                'fullname': order.fullname or '',
                'phone': order.phone or '',
                'address': order.address or '',
                'district': order.district or '',
                'product': product_description,
                'planning_status': status,
                'latitude': float(order.latitude) if order.latitude else None,
                'longitude': float(order.longitude) if order.longitude else None,
                'route_sequence': order.route_sequence or 0,
            })
        
        # Ordenar por route_sequence (menor a mayor)
        orders_with_data.sort(key=lambda o: o['route_sequence'])
        
        return {
            'success': True, 
            'orders': orders_with_data,
            'fleet_type': fleet_type,
            'fleet_license': fleet_license,
            'route_start_address': route_start_address,
            'route_start_latitude': route_start_latitude,
            'route_start_longitude': route_start_longitude,
            'route_status': route.state_route or 'to_validate',
        }

    @http.route('/driver/order/search_global', type='http', auth='public', csrf=False)
    def driver_order_search_global(self):
        """Busca una orden globalmente en el sistema y retorna su ruta y conductor si no está en la ruta actual"""
        import json
        
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return request.make_response(json.dumps({'success': False, 'error': 'Token no proporcionado'}), headers={'Content-Type': 'application/json'})
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return request.make_response(json.dumps({'success': False, 'error': 'Token inválido'}), headers={'Content-Type': 'application/json'})

        # Obtener código desde parámetros
        order_code = request.params.get('order_code', '').strip()
        
        if not order_code:
            return request.make_response(json.dumps({'success': False, 'error': 'Código de orden no proporcionado'}), headers={'Content-Type': 'application/json'})

        # Buscar por número de orden o código único
        order = request.env['trainyl.order'].sudo().search([
            '|',
            ('order_number', '=', order_code),
            ('unique_code', '=', order_code)
        ], limit=1)
        
        if not order:
            return request.make_response(json.dumps({'success': False, 'error': f'Orden {order_code} no encontrada en el sistema'}), headers={'Content-Type': 'application/json'})
        
        # Obtener la ruta actual del conductor (si existe)
        today = date.today()
        current_routes = request.env['trainyl.routes.extra'].sudo().search([
            ('driver_id', '=', employee.id),
            ('ruta_date', '=', today),
        ])
        
        current_route = current_routes[0] if current_routes else None
        
        # Verificar si está asignada a una ruta
        if order.route_id:
            route = order.route_id
            driver = route.driver_id
            belongs_to_another_route = bool(not current_route or current_route.id != route.id)
            
            # Si la orden pertenece a otra ruta, registrar el intento fallido en el log
            if belongs_to_another_route:
                order.sudo()._create_mobile_log_wrong_route_attempt(
                    attempted_driver_id=employee.id,
                    attempted_route_id=current_route.id
                )
            
            response_data = {
                'success': True,
                'found': True,
                'belongs_to_another_route': belongs_to_another_route,
                'order': {
                    'id': order.id,
                    'order_number': order.order_number or '',
                    'fullname': order.fullname or '',
                },
                'route_info': {
                    'route_id': route.id,
                    'route_name': route.name or '',
                    'driver_name': driver.name if driver else 'Sin asignar',
                    'driver_id': driver.id if driver else False,
                }
            }
            return request.make_response(json.dumps(response_data), headers={'Content-Type': 'application/json'})
        else:
            response_data = {
                'success': True,
                'found': True,
                'belongs_to_another_route': False,
                'order': {
                    'id': order.id,
                    'order_number': order.order_number or '',
                    'fullname': order.fullname or '',
                },
                'message': 'Esta orden no está asignada a ninguna ruta'
            }
            return request.make_response(json.dumps(response_data), headers={'Content-Type': 'application/json'})


    @http.route('/driver/order/detail/<int:order_id>', type='json', auth='public', csrf=False)
    def driver_order_detail(self, order_id):
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        order = request.env['trainyl.order'].sudo().search([
            ('id', '=', order_id)
        ], limit=1)
        
        if not order:
            return {'success': False, 'error': 'Orden no encontrada'}
        
        products = []
        for line in order.order_line_ids:
            if line.product_des:
                products.append(line.product_des)
        
        product_description = ', '.join(products) if products else 'N/A'
        status = order.expected_status or 'in_planification'
        
        return {
            'success': True, 
            'order': {
                'id': order.id,
                'order_number': order.order_number or '',
                'fullname': order.fullname or '',
                'phone': order.phone or '',
                'address': order.address or '',
                'district': order.district or '',
                'product': product_description,
                'planning_status': status,
                'latitude': float(order.latitude) if order.latitude else None,
                'longitude': float(order.longitude) if order.longitude else None,
            }
        }

    @http.route('/driver/order/start_next/<int:route_id>', type='json', auth='public', csrf=False)
    def driver_order_start_next(self, route_id):
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        route = request.env['trainyl.routes.extra'].sudo().search([
            ('id', '=', route_id),
            ('driver_id', '=', employee.id),
        ], limit=1)
        
        if not route:
            return {'success': False, 'error': 'Ruta no encontrada'}
        
        # Verificar si ya hay una orden en curso (start_of_route)
        orders_in_progress = route.order_ids.filtered(lambda o: o.expected_status == 'start_of_route')
        if orders_in_progress:
            return {
                'success': False, 
                'error': 'Ya tienes una orden en curso. Complétala antes de iniciar otra.',
                'order_in_progress': orders_in_progress[0].order_number or orders_in_progress[0].display_name
            }
        
        # Buscar órdenes en estado in_transport (siguientes a iniciar)
        in_transport_orders = route.order_ids.filtered(lambda o: o.expected_status == 'in_transport')
        
        if not in_transport_orders:
            return {'success': False, 'error': 'No hay órdenes en transporte para iniciar'}
        
        # Registrar logs para órdenes sin escanear (que quedaron en in_planification)
        unscanned_orders = route.order_ids.filtered(lambda o: o.expected_status == 'in_planification')
        for unscanned_order in unscanned_orders:
            unscanned_order.sudo()._create_mobile_log(
                message=f"Ruta iniciada sin escanear esta orden. Quedó en estado 'Planificado'",
                driver_id=employee.id,
                vehicle_id=route.fleet_id.id if route.fleet_id else False,
                expected_status='in_planification'
            )
        
        # Ordenar por route_sequence y seleccionar la primera
        in_transport_orders = in_transport_orders.sorted(key=lambda o: o.route_sequence or 0)
        next_order = in_transport_orders[0]
        next_order.sudo().write({'expected_status': 'start_of_route'})
        
        # Crear log para la orden que se está iniciando
        next_order.sudo()._create_mobile_log(
            message=f"Orden iniciada como primera de la ruta",
            driver_id=employee.id,
            vehicle_id=route.fleet_id.id if route.fleet_id else False,
            expected_status='start_of_route'
        )

        if route.state_route != 'in_route':
            route.sudo().write({'state_route': 'in_route'})
        
        return {
            'success': True,
            'message': 'Orden iniciada correctamente',
            'order_id': next_order.id,
            'order_number': next_order.order_number or next_order.display_name,
            'unscanned_count': len(unscanned_orders),
        }

    @http.route('/driver/order/start/<int:route_id>/<int:order_id>', type='json', auth='public', csrf=False)
    def driver_order_start_specific(self, route_id, order_id):
        """Inicia una orden específica manualmente, detecta si saltó la secuencia planificada"""
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        # Buscar ruta
        route = request.env['trainyl.routes.extra'].sudo().search([
            ('id', '=', route_id),
            ('driver_id', '=', employee.id),
        ], limit=1)
        
        if not route:
            return {'success': False, 'error': 'Ruta no encontrada'}
        
        # Verificar si ya hay una orden en curso (start_of_route)
        orders_in_progress = route.order_ids.filtered(lambda o: o.expected_status == 'start_of_route')
        if orders_in_progress:
            return {
                'success': False, 
                'error': 'Ya tienes una orden en curso. Complétala antes de iniciar otra.',
                'order_in_progress': orders_in_progress[0].order_number or orders_in_progress[0].display_name
            }
        
        # Obtener orden seleccionada
        selected_order = request.env['trainyl.order'].sudo().search([
            ('id', '=', order_id)
        ], limit=1)
        
        if not selected_order:
            return {'success': False, 'error': 'Orden no encontrada'}
        
        # Obtener órdenes pendientes (in_planification o in_transport) ordenadas por secuencia
        pending_orders = route.order_ids.filtered(
            lambda o: o.expected_status in ['in_planification', 'in_transport']
        ).sorted(key=lambda o: o.route_sequence or 0)
        
        if not pending_orders:
            return {'success': False, 'error': 'No hay órdenes disponibles para iniciar. Todas las órdenes ya están en curso o completadas.'}
        
        # Detectar si es la orden planeada (primera en secuencia) o si saltó
        planned_order = pending_orders[0]
        skipped_sequence = planned_order.id != selected_order.id
        
        # Actualizar estado de la orden seleccionada
        selected_order.sudo().write({'expected_status': 'start_of_route'})

        if route.state_route != 'in_route':
            route.sudo().write({'state_route': 'in_route'})
        
        # Crear log descriptivo en trainyl.mobile.log
        if skipped_sequence:
            # El conductor saltó la secuencia planificada
            message = (
                f"Conductor saltó la planificación. "
                f"Inició orden {selected_order.order_number or 'N/A'} (Pos {selected_order.route_sequence or 0}) "
                f"en vez de la orden recomendada {planned_order.order_number or 'N/A'} (Pos {planned_order.route_sequence or 0})"
            )
        else:
            # El conductor siguió la secuencia planificada
            message = (
                f"Conductor siguió la planificación. "
                f"Inició orden {selected_order.order_number or 'N/A'} (Pos {selected_order.route_sequence or 0})"
            )
        
        # Crear registro en el log
        selected_order.sudo()._create_mobile_log(
            message=message,
            driver_id=employee.id,
            vehicle_id=route.fleet_id.id if route.fleet_id else False,
            expected_status='start_of_route',
            reason_rejection_id=False,
            reason_for_rejection=False,
            photo_1=False,
            photo_2=False,
        )
        
        return {
            'success': True,
            'message': 'Orden iniciada correctamente',
            'order_id': selected_order.id,
            'order_number': selected_order.order_number or selected_order.display_name,
            'skipped_sequence': skipped_sequence,
        }

    @http.route('/driver/order/start_next_from_current/<int:route_id>/<int:current_order_id>', type='json', auth='public', csrf=False)
    def driver_order_start_next_from_current(self, route_id, current_order_id):
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            return {'success': False, 'error': 'Token inválido'}

        # Obtener orden actual (donde estamos)
        current_order = request.env['trainyl.order'].sudo().search([
            ('id', '=', current_order_id)
        ], limit=1)
        
        if not current_order:
            return {'success': False, 'error': 'Orden actual no encontrada'}
        
        # Buscar ruta
        route = request.env['trainyl.routes.extra'].sudo().search([
            ('id', '=', route_id),
            ('driver_id', '=', employee.id),
        ], limit=1)
        
        if not route:
            return {'success': False, 'error': 'Ruta no encontrada'}
        
        # Obtener órdenes en estado in_transport
        in_transport_orders = route.order_ids.filtered(
            lambda o: o.expected_status == 'in_transport'
        )
        
        if not in_transport_orders:
            return {'success': False, 'error': 'No hay órdenes en transporte para iniciar'}
        
        # Ordenar por route_sequence y seleccionar la primera
        in_transport_orders = in_transport_orders.sorted(key=lambda o: o.route_sequence or 0)
        next_order = in_transport_orders[0]
        next_order.sudo().write({'expected_status': 'start_of_route'})

        if route.state_route != 'in_route':
            route.sudo().write({'state_route': 'in_route'})
        
        return {
            'success': True,
            'message': 'Siguiente orden iniciada correctamente desde ubicación actual',
            'order_id': next_order.id,
            'order_number': next_order.order_number or next_order.display_name,
            'fullname': next_order.fullname or '',
            'phone': next_order.phone or '',
            'address': next_order.address or '',
            'district': next_order.district or '',
            'latitude': float(next_order.latitude) if next_order.latitude else None,
            'longitude': float(next_order.longitude) if next_order.longitude else None,
        }

    @http.route('/driver/order/scan_confirm/<int:order_id>', type='json', auth='public', csrf=False)
    def driver_order_scan_confirm(self, order_id):
        """Confirma el escaneo/búsqueda de una orden y cambia su estado de in_planification a in_transport"""
        import logging
        _logger = logging.getLogger(__name__)
        
        _logger.info("🔵 ===== INICIO scan_confirm para orden ID: %s =====", order_id)
        
        auth_header = request.httprequest.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            _logger.warning("❌ Token no proporcionado")
            return {'success': False, 'error': 'Token no proporcionado'}
        
        token = auth_header.replace('Bearer ', '').strip()
        _logger.info("🔵 Token recibido: %s...", token[:20])
        
        employee = request.env['hr.employee'].sudo().search([
            ('api_token', '=', token)
        ], limit=1)
        
        if not employee:
            _logger.warning("❌ Token inválido")
            return {'success': False, 'error': 'Token inválido'}
        
        _logger.info("✅ Conductor autenticado: %s (ID: %s)", employee.name, employee.id)

        # Buscar la orden
        order = request.env['trainyl.order'].sudo().search([
            ('id', '=', order_id)
        ], limit=1)
        
        if not order:
            _logger.warning("❌ Orden %s no encontrada", order_id)
            return {'success': False, 'error': 'Orden no encontrada'}
        
        _logger.info("✅ Orden encontrada: %s (ID: %s)", order.order_number, order.id)
        _logger.info("🔵 Estado ANTES del cambio: %s", order.expected_status)
        
        # Validar que la orden esté en estado in_planification
        if order.expected_status != 'in_planification':
            _logger.warning("❌ Orden NO está en in_planification. Estado actual: %s", order.expected_status)
            return {
                'success': False, 
                'error': f'La orden debe estar en estado EN PLANIFICACIÓN. Estado actual: {order.expected_status}'
            }
        
        # Cambiar estado a in_transport
        _logger.info("🔵 Intentando cambiar estado a in_transport...")
        try:
            order.sudo().write({'expected_status': 'in_transport'})
            request.env.cr.commit()  # Forzar commit de la transacción
            _logger.info("✅ write() ejecutado exitosamente")
        except Exception as e:
            _logger.error("❌ Error en write(): %s", str(e))
            return {'success': False, 'error': f'Error al actualizar: {str(e)}'}
        
        # Verificar que el cambio se aplicó
        request.env.invalidate_all()  # Limpiar cache del environment
        order = request.env['trainyl.order'].sudo().browse(order_id)  # Recargar desde BD
        _logger.info("🔵 Estado DESPUÉS del cambio (recargado): %s", order.expected_status)
        
        if order.expected_status != 'in_transport':
            _logger.error("❌ ¡PROBLEMA! El estado NO cambió. Sigue siendo: %s", order.expected_status)
            return {
                'success': False,
                'error': f'El estado no se actualizó. Estado actual: {order.expected_status}'
            }
        
        _logger.info("✅ Estado confirmado como in_transport")
        
        # Crear log de trazabilidad
        _logger.info("🔵 Creando log de trazabilidad...")
        try:
            # Obtener el vehículo de la ruta de la orden
            route = order.sudo().route_id
            vehicle_id = route.fleet_id.id if route and route.fleet_id else False
            
            order.sudo()._create_mobile_log(
                message=f"Orden escaneada/confirmada por conductor {employee.name}. Estado cambiado de EN PLANIFICACIÓN a EN TRANSPORTE",
                driver_id=employee.id,
                vehicle_id=vehicle_id,
                expected_status='in_transport'
            )
            _logger.info("✅ Log de trazabilidad creado")
        except Exception as e:
            _logger.error("❌ Error creando log: %s", str(e))
        
        _logger.info("🔵 ===== FIN scan_confirm - Éxito =====")
        
        return {
            'success': True,
            'message': 'Orden confirmada y cambiada a EN TRANSPORTE',
            'order_id': order.id,
            'order_number': order.order_number or order.display_name,
            'new_status': 'in_transport',
        }
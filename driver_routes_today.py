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
        
        for order in route.order_ids:
            products = []
            for line in order.order_line_ids:
                if line.product_des:
                    products.append(line.product_des)
            
            product_description = ', '.join(products) if products else 'N/A'
            status = order.expected_status or 'pending'
            
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
        }

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
        status = order.expected_status or 'pending'
        
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
        
        pending_orders = route.order_ids.filtered(lambda o: o.expected_status == 'pending')
        
        if not pending_orders:
            return {'success': False, 'error': 'No hay órdenes pendientes para iniciar'}
        
        # Ordenar por route_sequence y seleccionar la primera
        pending_orders = pending_orders.sorted(key=lambda o: o.route_sequence or 0)
        next_order = pending_orders[0]
        next_order.sudo().write({'expected_status': 'start_of_route'})
        
        return {
            'success': True,
            'message': 'Orden iniciada correctamente',
            'order_id': next_order.id,
            'order_number': next_order.order_number or next_order.display_name,
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
        
        # Obtener orden seleccionada
        selected_order = request.env['trainyl.order'].sudo().search([
            ('id', '=', order_id)
        ], limit=1)
        
        if not selected_order:
            return {'success': False, 'error': 'Orden no encontrada'}
        
        # Obtener órdenes pendientes ordenadas por secuencia
        pending_orders = route.order_ids.filtered(
            lambda o: o.expected_status == 'pending'
        ).sorted(key=lambda o: o.route_sequence or 0)
        
        if not pending_orders:
            return {'success': False, 'error': 'No hay órdenes pendientes'}
        
        # Detectar si es la orden planeada (primera en secuencia) o si saltó
        planned_order = pending_orders[0]
        skipped_sequence = planned_order.id != selected_order.id
        
        # Actualizar estado de la orden seleccionada
        selected_order.sudo().write({'expected_status': 'start_of_route'})
        
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
        
        # Obtener órdenes pendientes
        pending_orders = route.order_ids.filtered(
            lambda o: o.expected_status == 'pending'
        )
        
        if not pending_orders:
            return {'success': False, 'error': 'No hay órdenes pendientes para iniciar'}
        
        # Ordenar por route_sequence y seleccionar la primera
        pending_orders = pending_orders.sorted(key=lambda o: o.route_sequence or 0)
        next_order = pending_orders[0]
        next_order.sudo().write({'expected_status': 'start_of_route'})
        
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
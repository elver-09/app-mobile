from odoo import http
from odoo.http import request
from datetime import datetime
import logging

_logger = logging.getLogger(__name__)

def parse_iso8601_datetime(iso_string):
    """Convierte ISO8601 a formato datetime de Odoo"""
    if not iso_string:
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    try:
        # Parsear ISO8601
        dt = datetime.fromisoformat(iso_string.replace('Z', '+00:00'))
        # Convertir a string en formato Odoo
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except Exception as e:
        _logger.warning(f"Error parseando datetime '{iso_string}': {e}")
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

class DriverOrderUpdateController(http.Controller):

    @http.route('/driver/order/update_delivered', type='json', auth='public', csrf=False)
    def update_delivered(self):
        """Recibe notificación de entrega desde app"""
        try:
            auth_header = request.httprequest.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return {'success': False, 'error': 'Token no proporcionado'}
            
            token = auth_header.replace('Bearer ', '').strip()
            
            employee = request.env['hr.employee'].sudo().search([
                ('api_token', '=', token)
            ], limit=1)
            
            if not employee:
                return {'success': False, 'error': 'Token inválido'}
            
            order_id = request.params.get('order_id')
            recipient_name = request.params.get('recipient_name')
            delivery_photos = request.params.get('delivery_photos', [])
            
            if not order_id:
                return {'success': False, 'error': 'order_id es requerido'}
            
            order = request.env['trainyl.order'].sudo().search([
                ('id', '=', int(order_id))
            ], limit=1)
            
            if not order:
                return {'success': False, 'error': 'Orden no encontrada'}
            
            # Actualizar estado en la orden
            order.sudo().write({
                'expected_status': 'delivered',
            })

            # Guardar evidencia en el modelo de log (trainyl.mobile.log)
            photo_1 = delivery_photos[0] if delivery_photos and len(delivery_photos) > 0 else False
            photo_2 = delivery_photos[1] if delivery_photos and len(delivery_photos) > 1 else False

            message = 'Entrega confirmada desde app.'
            if recipient_name:
                message = f"{message} Receptor: {recipient_name}"

            # Obtener conductor y vehículo desde la ruta
            route = order.sudo().route_id
            driver_id = route.driver_id.id if route and route.driver_id else False
            vehicle_id = route.fleet_id.id if route and route.fleet_id else False

            order.sudo()._create_mobile_log(
                message=message,
                driver_id=driver_id,
                vehicle_id=vehicle_id,
                expected_status='delivered',
                reason_rejection_id=False,
                reason_for_rejection=False,
                photo_1=photo_1,
                photo_2=photo_2,
            )
            
            # Verificar si la ruta está completa (todas las órdenes entregadas o rechazadas)
            if route:
                pending_orders = route.order_ids.filtered(lambda o: o.expected_status in ['in_planification', 'in_transport', 'start_of_route'])
                if not pending_orders:
                    # No hay más órdenes pendientes, marcar ruta como terminada
                    route.sudo().write({'state_route': 'finished'})
                    _logger.info(f"✅ Ruta {route.name} marcada como terminada")
            
            _logger.info(f"✅ Orden {order_id} entregada por app")
            return {'success': True, 'message': 'Entrega registrada'}
            
        except Exception as e:
            _logger.error(f"❌ Error en update_delivered: {str(e)}", exc_info=True)
            return {'success': False, 'error': str(e)}

    @http.route('/driver/order/update_rejected', type='json', auth='public', csrf=False)
    def update_rejected(self):
        """Recibe notificación de rechazo desde app"""
        try:
            auth_header = request.httprequest.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return {'success': False, 'error': 'Token no proporcionado'}
            
            token = auth_header.replace('Bearer ', '').strip()
            
            employee = request.env['hr.employee'].sudo().search([
                ('api_token', '=', token)
            ], limit=1)
            
            if not employee:
                return {'success': False, 'error': 'Token inválido'}
            
            order_id = request.params.get('order_id')
            reject_reason = request.params.get('reject_reason')
            reject_reason_id = request.params.get('reject_reason_id')  # ← ID dinámico desde BD
            reject_comment = request.params.get('reject_comment')
            reject_photos = request.params.get('reject_photos', [])
            
            if not order_id:
                return {'success': False, 'error': 'order_id es requerido'}
            
            order = request.env['trainyl.order'].sudo().search([
                ('id', '=', int(order_id))
            ], limit=1)
            
            if not order:
                return {'success': False, 'error': 'Orden no encontrada'}
            
            # Resolver razón de rechazo dinámica (si viene) - PRIMERO
            reason_rejection_id_value = False
            reason_name = ''
            
            if reject_reason_id:
                try:
                    rejection_reason = request.env['trainyl.rejection.reason'].sudo().search([
                        ('id', '=', int(reject_reason_id))
                    ], limit=1)
                    if rejection_reason:
                        reason_rejection_id_value = rejection_reason.id
                        reason_name = rejection_reason.name
                        _logger.info(f"✅ Razón de rechazo asignada: {reason_name}")
                    else:
                        _logger.warning(f"⚠️ Razón de rechazo {reject_reason_id} no encontrada")
                except Exception as e:
                    _logger.warning(f"⚠️ Error asignando razón de rechazo: {e}")
            
            # Actualizar estado en la orden - DESPUÉS de obtener reason_rejection_id_value
            order.sudo().write({
                'expected_status': 'cancelled',
                'reason_rejection_id': reason_rejection_id_value if reason_rejection_id_value else False,
            })

            # Guardar evidencia en el modelo de log (trainyl.mobile.log)
            photo_1 = reject_photos[0] if reject_photos and len(reject_photos) > 0 else False
            photo_2 = reject_photos[1] if reject_photos and len(reject_photos) > 1 else False

            # Construir mensaje descriptivo con la razón y comentario
            message_parts = ['Rechazo registrado desde app.']
            
            if reason_name:
                message_parts.append(f"Razón: {reason_name}")
            
            if reject_comment:
                message_parts.append(f"Comentario: {reject_comment}")
            
            message = ' | '.join(message_parts)

            # Obtener conductor y vehículo desde la ruta
            route = order.sudo().route_id
            driver_id = route.driver_id.id if route and route.driver_id else False
            vehicle_id = route.fleet_id.id if route and route.fleet_id else False

            order.sudo()._create_mobile_log(
                message=message,
                driver_id=driver_id,
                vehicle_id=vehicle_id,
                expected_status='cancelled',
                reason_rejection_id=reason_rejection_id_value,
                reason_for_rejection=reject_comment or False,
                photo_1=photo_1,
                photo_2=photo_2,
            )
            
            # Verificar si la ruta está completa (todas las órdenes entregadas o rechazadas)
            if route:
                pending_orders = route.order_ids.filtered(lambda o: o.expected_status in ['in_planification', 'in_transport', 'start_of_route'])
                if not pending_orders:
                    # No hay más órdenes pendientes, marcar ruta como terminada
                    route.sudo().write({'state_route': 'finished'})
                    _logger.info(f"✅ Ruta {route.name} marcada como terminada")
            
            _logger.info(f"✅ Orden {order_id} rechazada por app")
            return {'success': True, 'message': 'Rechazo registrado'}
        except Exception as e:
            _logger.error(f"❌ Error en update_rejected: {str(e)}", exc_info=True)
            return {'success': False, 'error': str(e)}

    @http.route('/driver/rejection/reasons', type='json', auth='public', csrf=False)
    def get_rejection_reasons(self):
        """Obtiene las razones de rechazo disponibles para móvil"""
        try:
            auth_header = request.httprequest.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return {'success': False, 'error': 'Token no proporcionado'}
            
            token = auth_header.replace('Bearer ', '').strip()
            
            employee = request.env['hr.employee'].sudo().search([
                ('api_token', '=', token)
            ], limit=1)
            
            if not employee:
                return {'success': False, 'error': 'Token inválido'}
            
            # Obtener razones de rechazo activas en móvil
            reasons = request.env['trainyl.rejection.reason'].sudo().search([
                ('in_mobile', '=', True)
            ])
            
            reasons_data = []
            for reason in reasons:
                reasons_data.append({
                    'id': reason.id,
                    'name': reason.name,
                    'need_note': reason.need_note,
                })
            
            return {'success': True, 'reasons': reasons_data}
        
        except Exception as e:
            _logger.error(f"❌ Error en get_rejection_reasons: {str(e)}", exc_info=True)
            return {'success': False, 'error': str(e)}
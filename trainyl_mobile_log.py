from odoo import models, fields

class TrainylMobileLog(models.Model):
    _name = 'trainyl.mobile.log'
    _description = 'Log de cambios desde App Mobile'
    _order = 'create_date desc, id desc'

    order_id = fields.Many2one('trainyl.order', string='Orden', ondelete='cascade', index=True)
    date_time = fields.Datetime(string='Fecha y Hora', default=fields.Datetime.now, readonly=True)
    driver_id = fields.Many2one('hr.employee', string='Conductor Asignado', readonly=True)
    vehicle_id = fields.Many2one('trainyl.fleet', string='Vehículo Asignado', readonly=True)
    expected_status = fields.Selection([
        ('draft', 'BORRADOR'),
        ('in_trainyl', 'EN TRAINYL'),  
        ('ready_for_drivin', 'LISTO PARA DRIVIN'),  
        ('pending', 'PISTOLEADO'),
        # PENDIENTE
        ('start_of_route', 'INICIO DE RUTA'),
        ('in_planification', 'EN PLANIFICACIÓN'),
        ('in_transport', 'EN TRANSPORTE'),
        # DELIVERED
        ('delivered', 'ENTREGADO'),
        ('sent_do_yango', 'ENVIADO POR YANGO'),
        # REJECTED
        ('cancelled', 'RECHAZADO'), 
        ('blocked', 'BLOQUEADO'),
        ('anulled', 'ANULADO'),
        ('returned', 'DEVUELTO A TIENDA'),
        ('hand_to_hand', 'MANO A MANO'),
        ('cancelled_origin', 'CANCELADO DESDE ORIGEN'),
    ], string='Estado de Envio', default='draft')
    message = fields.Text(string='Mensaje', required=True)
    reason_rejection_id = fields.Many2one('trainyl.rejection.reason', string='Razón de Rechazo')
    reason_for_rejection = fields.Text(string='Motivo de Rechazo')
    photo_1 = fields.Binary(string='Foto 1', attachment=True)
    photo_2 = fields.Binary(string='Foto 2', attachment=True)
    photo_3 = fields.Binary(string='Foto 3', attachment=True)
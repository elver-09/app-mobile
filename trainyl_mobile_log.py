from odoo import models, fields

class TrainylMobileLog(models.Model):
    _name = 'trainyl.mobile.log'
    _description = 'Log de cambios desde App Mobile'
    _order = 'create_date desc, id desc'

    order_id = fields.Many2one('trainyl.order', string='Orden', ondelete='cascade', index=True)
    date_time = fields.Datetime(string='Fecha y Hora', default=fields.Datetime.now, readonly=True)
    driver_id = fields.Many2one('hr.employee', string='Conductor Asignado', readonly=True)
    vehicle_id = fields.Many2one('trainyl.fleet', string='Vehículo Asignado', readonly=True)
    new_status_orders = fields.Selection([
        ('draft', 'BORRADOR'),
        ('reprogrammed', 'REPROGRAMADO'),
        ('in_trainyl', 'EN TRAINYL'),
        ('in_planification', 'PLANIFICADO'),
        ('blocked', 'BLOQUEADO'),
        ('in_transport', 'EN TRANSPORTE'),
        ('delivered', 'ENTREGADO'),
        ('cancelled', 'RECHAZADO')], string='Nuevo Estado', default='draft', readonly=True)
    message = fields.Text(string='Mensaje', required=True)
    reason_rejection_id = fields.Many2one('trainyl.rejection.reason', string='Razón de Rechazo')
    reason_for_rejection = fields.Text(string='Motivo de Rechazo')
    photo_1 = fields.Binary(string='Foto 1', attachment=True)
    photo_2 = fields.Binary(string='Foto 2', attachment=True)
    photo_3 = fields.Binary(string='Foto 3', attachment=True)
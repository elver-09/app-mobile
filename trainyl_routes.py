from odoo import models, fields, api

class TrainylRoutesExtra(models.Model):
    _name = 'trainyl.routes.extra'
    _description = 'Ruta de Planificación'

    order_ids = fields.One2many('trainyl.order','route_id', string = 'Ordenes')
    name = fields.Char(string='Nombre', store=True)
    driver_id = fields.Many2one('hr.employee', string='Chofer')
    fleet_id = fields.Many2one('trainyl.fleet', string='Vehículo')
    zone_id = fields.Many2one('trainyl.zone', string='Zona')
    planificacion_id = fields.Many2one('trainyl.planification.extra', string='Planificación', ondelete='cascade')
    state_route = fields.Selection([
        ('to_validate', 'Por Validar'),
        ('in_route', 'En Ruta'),
        ('finished', 'Terminado')
    ], string='Estado de la Ruta', default='to_validate')
    ruta_date = fields.Date(string='Fecha')

    def action_view_orders(self):
        self.ensure_one()
        return {
            'name': 'Órdenes de la Ruta',
            'type': 'ir.actions.act_window',
            'res_model': 'trainyl.order',
            'view_mode': 'list,form',
            'domain': [('route_id', '=', self.id)],
            'context': {'default_route_id': self.id},
        }

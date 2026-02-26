from odoo import models, fields, api
from odoo.exceptions import UserError
import base64
import io
import xlsxwriter

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

    districts_ids = fields.Many2many(
        'l10n_pe.res.city.district',
        string='Distritos en la Ruta',
        compute='_compute_districts_ids',
        store=True)
    order_count = fields.Integer(
        string='Cantidad de Órdenes',
        compute='_compute_order_count',
        store=True)

    @api.depends('order_ids.area_id')
    def _compute_districts_ids(self):
        for rec in self:
            district_ids = rec.order_ids.mapped('area_id.id')
            rec.districts_ids = [(6, 0, list(set(district_ids)))] if district_ids else [(5, 0, 0)]

    @api.depends('order_ids')
    def _compute_order_count(self):
        for rec in self:
            rec.order_count = len(rec.order_ids)

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
    
    def action_open_route_order_add_wizard(self):
        """Abre el wizard para agregar órdenes manualmente a esta ruta."""
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Agregar órdenes a rutas',
            'res_model': 'route.order.add.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {
                'default_route_id': self.id,
                'default_planificacion_id': self.planificacion_id.id if self.planificacion_id else False,
                'default_zone_id': self.zone_id.id if self.zone_id else False,
                'default_date_start': self.ruta_date,
                'default_date_end': self.ruta_date,
            }
        }
    
    def action_print_excel(self):
        try:
            self.ensure_one()
            output = io.BytesIO()
            workbook = xlsxwriter.Workbook(output)
            worksheet = workbook.add_worksheet('Órdenes')

            # --- Encabezado general ---
            bold = workbook.add_format({'bold': True})
            border = workbook.add_format({'border': 1})
            bold_border = workbook.add_format({'bold': True, 'border': 1})
            center = workbook.add_format({'align': 'center'})
            header_format = workbook.add_format({'bold': True, 'font_color': 'white', 'bg_color': 'black', 'border': 1, 'align': 'center'})

            # Datos generales
            worksheet.write('A1', 'FECHA', bold)
            worksheet.write('B1', self.ruta_date.strftime('%d/%m/%Y') if self.ruta_date else '', border)
            worksheet.write('A2', 'N° RUTA:', bold)
            worksheet.write('B2', self.name or '', border)
            worksheet.write('A3', 'CONDUCTOR', bold)
            worksheet.write('B3', self.driver_id.name or '', border)
            worksheet.write('A4', 'PLACA', bold)
            worksheet.write('B4', self.fleet_id.license_plate or '', border)

            # Logo desde la compañía
            import tempfile, base64
            company_logo = self.env.company.logo
            if company_logo:
                try:
                    with tempfile.NamedTemporaryFile(delete=False, suffix='.png') as tmp_logo:
                        tmp_logo.write(base64.b64decode(company_logo))
                        tmp_logo.flush()
                        worksheet.insert_image('G1', tmp_logo.name, {'x_scale': 0.7, 'y_scale': 0.7, 'x_offset': 10, 'y_offset': -15})
                except Exception:
                    pass

            # --- Encabezados de columnas ---
            headers = [
                'Numero de Orden', 'Cliente', 'Líneas de pedido', 'Linea', 'Distrito', 'DNI', 'Nombre del Cliente', 'Dirección', 'Teléfono', 'Origen', 'Escaneado', 'No Escaneado'
            ]
            column_widths = [25, 25, 30, 6, 15, 18, 25, 35, 18, 15, 10, 10]
            row_start = 6
            for col, (header, width) in enumerate(zip(headers, column_widths)):
                worksheet.set_column(col, col, width)
                worksheet.write(row_start, col, header, header_format)

            # --- Filas de órdenes ---
            row = row_start + 1
            center_icon = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
            for order in self.order_ids:
                # Concatenar líneas de pedido usando product_des
                lineas = ', '.join([l.product_des or '' for l in getattr(order, 'order_line_ids', [])])
                worksheet.write(row, 0, order.order_number or '', border)
                worksheet.write(row, 1, order.partner_id.name or order.fullname or '', border)
                worksheet.write(row, 2, lineas, border)
                worksheet.write(row, 3, '1', border)  # Si tienes el número de línea real, cámbialo aquí
                worksheet.write(row, 4, order.district or '', border)
                worksheet.write(row, 5, f"DNI: {order.dispatch_id}" if order.dispatch_id else '', border)
                worksheet.write(row, 6, order.fullname or '', border)
                worksheet.write(row, 7, order.address or '', border)
                worksheet.write(row, 8, order.phone or '', border)
                # Mostrar Origen
                origen_map = {'entry': 'Ingreso', 'reprogramming': 'Reprogramación'}
                worksheet.write(row, 9, origen_map.get(order.repro_entry, ''), border)
                # Columna Escaneado
                worksheet.write(row, 10, '✅' if getattr(order, 'scanned', False) else '', center_icon)
                # Columna No Escaneado
                worksheet.write(row, 11, '❌' if getattr(order, 'not_scanned', False) else '', center_icon)
                row += 1

            workbook.close()
            output.seek(0)
            file_data = base64.b64encode(output.read()).decode('utf-8')
            file_name = f'Cargo_Ruta_{self.name or ""}.xlsx'

            attachment = self.env['ir.attachment'].create({
                'name': file_name,
                'type': 'binary',
                'datas': file_data,
                'store_fname': file_name,
                'mimetype': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'res_model': 'trainyl.routes.extra',
                'res_id': self.id,
            })

            return {
                'type': 'ir.actions.act_url',
                'url': f'/web/content/{attachment.id}?download=true',
                'target': 'self',
                'close_on_report_download': True,
            }
        except Exception as e:
            raise UserError(f"Error al generar el Excel: {str(e)}")

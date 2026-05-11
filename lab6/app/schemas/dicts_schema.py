from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields, validate
from ..models.dicts import Dicts

class DictsSchema(SQLAlchemyAutoSchema):
    id = fields.Int(dump_only=True)  # только для чтения, генерируется БД
    user_id = fields.Int(required=True, error_messages={"required": "user_id обязателен"})
    title = fields.Str(
        required=True,
        validate=validate.Length(min=1, max=255, error="Название словаря должно быть от 1 до 255 символов"),
        error_messages={"required": "Название словаря обязательно"}
    )
    description = fields.Str(
        required=True,
        validate=validate.Length(min=0, max=1000, error="Описание не более 1000 символов"),
        error_messages={"required": "Описание словаря обязательно"}
    )

    class Meta:
        model = Dicts
        load_instance = True          # позволяет создавать объекты модели из данных
        include_fk = True             # включает внешние ключи (user_id)
        dump_only = ('id',)          # id только для чтения при сериализации
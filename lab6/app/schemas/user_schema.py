from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields
from ..models.user import Users

class UserSchema(SQLAlchemyAutoSchema):
    name = fields.Str(required=True, error_messages={"required": "Имя обязательно"})
    email = fields.Email(required=True, error_messages={"required": "Email обязателен", "invalid": "Некорректный email"})

    class Meta:
        model = Users
        load_instance = True
        include_fk = True
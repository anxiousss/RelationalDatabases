from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields, validate
from ..models.words import Words

class WordsSchema(SQLAlchemyAutoSchema):
    id = fields.Int(dump_only=True)
    key = fields.Str(
        required=True,
        validate=validate.Length(min=1, max=255, error="Ключ слова должен быть от 1 до 255 символов"),
        error_messages={"required": "Ключ слова обязателен"}
    )
    value = fields.Str(
        required=True,
        validate=validate.Length(min=1, max=255, error="Значение слова должно быть от 1 до 255 символов"),
        error_messages={"required": "Значение слова обязательно"}
    )

    class Meta:
        model = Words
        load_instance = True
        include_fk = False          # у модели Words нет внешних ключей
        dump_only = ('id',)
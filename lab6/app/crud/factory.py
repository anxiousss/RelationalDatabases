from flask import request, jsonify
from marshmallow import ValidationError
from sqlalchemy.exc import IntegrityError
from sqlalchemy import asc, desc, or_
from .. import db

def register_crud_routes(app, model, schema, prefix, page_size=None):
    if page_size is None:
        page_size = app.config.get('DEFAULT_PAGE_SIZE', 10)
    model_name = model.__name__.lower()

    @app.route(f'/{prefix}/', methods=['GET'], endpoint=f'{prefix}_list')
    def get_all():
        """
        Получить список всех записей с пагинацией, сортировкой и фильтрацией
        ---
        tags:
          - {prefix.capitalize()}
        parameters:
          - name: page
            in: query
            type: integer
            default: 1
            description: Номер страницы
          - name: limit
            in: query
            type: integer
            default: 10
            description: Количество записей на странице (1-100)
          - name: sort
            in: query
            type: string
            default: id
            description: Поле для сортировки (например, id, name)
          - name: order
            in: query
            type: string
            enum: [asc, desc]
            default: asc
            description: Направление сортировки
          - name: filter
            in: query
            type: string
            description: Поиск по текстовым полям (нечёткое совпадение)
        responses:
          200:
            description: Успешный ответ
            schema:
              type: object
              properties:
                items:
                  type: array
                  items:
                    $ref: '#/definitions/{model.__name__}'
                total:
                  type: integer
                page:
                  type: integer
                pages:
                  type: integer
                per_page:
                  type: integer
          400:
            description: Ошибка валидации параметров
          500:
            description: Внутренняя ошибка сервера
        """
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('limit', page_size, type=int)
            sort_field = request.args.get('sort', 'id')
            order = request.args.get('order', 'asc')
            filter_value = request.args.get('filter', '')

            if page < 1:
                raise ValueError('page должен быть >= 1')
            if per_page < 1 or per_page > 100:
                raise ValueError('limit должен быть от 1 до 100')
            if order not in ('asc', 'desc'):
                raise ValueError('order должен быть asc или desc')

            query = model.query
            if filter_value:
                search_filters = []
                for column in model.__table__.columns:
                    if isinstance(column.type, db.String):
                        search_filters.append(getattr(model, column.name).ilike(f'%{filter_value}%'))
                if search_filters:
                    query = query.filter(or_(*search_filters))

            if hasattr(model, sort_field):
                order_func = asc if order == 'asc' else desc
                query = query.order_by(order_func(getattr(model, sort_field)))

            pagination = query.paginate(page=page, per_page=per_page, error_out=False)
            return jsonify({
                'items': schema.dump(pagination.items, many=True),
                'total': pagination.total,
                'page': page,
                'pages': pagination.pages,
                'per_page': per_page
            }), 200
        except ValueError as e:
            return jsonify({'error': str(e)}), 400
        except Exception as e:
            return jsonify({'error': f'Ошибка получения списка: {str(e)}'}), 500

    @app.route(f'/{prefix}/<int:item_id>', methods=['GET'], endpoint=f'{prefix}_detail')
    def get_one(item_id):
        """
        Получить запись по ID
        ---
        tags:
          - {prefix.capitalize()}
        parameters:
          - name: item_id
            in: path
            type: integer
            required: true
            description: ID записи
        responses:
          200:
            description: Объект найден
            schema:
              $ref: '#/definitions/{model.__name__}'
          404:
            description: Запись не найдена
        """
        try:
            item = model.query.get(item_id)
            if not item:
                return jsonify({'error': f'{model_name} не найден'}), 404
            return jsonify(schema.dump(item)), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route(f'/{prefix}/', methods=['POST'], endpoint=f'{prefix}_create')
    def create():
        """
        Создать новую запись
        ---
        tags:
          - {prefix.capitalize()}
        parameters:
          - name: body
            in: body
            required: true
            schema:
              $ref: '#/definitions/{model.__name__}Create'
        responses:
          201:
            description: Запись создана
            schema:
              $ref: '#/definitions/{model.__name__}'
          400:
            description: Ошибка валидации или неверный JSON
          409:
            description: Конфликт уникальности
        """
        try:
            data = request.get_json()
            if not data:
                return jsonify({'error': 'Отсутствуют данные в запросе'}), 400
            # Передаём сессию БД
            item = schema.load(data, session=db.session)
            db.session.add(item)
            db.session.commit()
            return jsonify(schema.dump(item)), 201
        except ValidationError as err:
            return jsonify({'error': 'Ошибка валидации', 'details': err.messages}), 400
        except IntegrityError as e:
            db.session.rollback()
            if 'unique constraint' in str(e.orig).lower() or 'duplicate key' in str(e.orig).lower():
                return jsonify({'error': 'Запись с таким уникальным полем уже существует'}), 409
            return jsonify({'error': 'Ошибка целостности данных'}), 409
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Ошибка создания: {str(e)}'}), 500

    @app.route(f'/{prefix}/<int:item_id>', methods=['PUT'], endpoint=f'{prefix}_update')
    def update(item_id):
        """
        Обновить запись (частичное обновление)
        ---
        tags:
          - {prefix.capitalize()}
        parameters:
          - name: item_id
            in: path
            type: integer
            required: true
          - name: body
            in: body
            required: true
            schema:
              type: object
              additionalProperties: true
        responses:
          200:
            description: Обновлённая запись
            schema:
              $ref: '#/definitions/{model.__name__}'
          400:
            description: Ошибка валидации
          404:
            description: Запись не найдена
          409:
            description: Конфликт уникальности
        """
        try:
            item = model.query.get(item_id)
            if not item:
                return jsonify({'error': f'{model_name} не найден'}), 404
            data = request.get_json()
            if not data:
                return jsonify({'error': 'Отсутствуют данные в запросе'}), 400
            updated_item = schema.load(data, instance=item, session=db.session, partial=True)
            db.session.commit()
            return jsonify(schema.dump(updated_item)), 200
        except ValidationError as err:
            return jsonify({'error': 'Ошибка валидации', 'details': err.messages}), 400
        except IntegrityError as e:
            db.session.rollback()
            if 'unique constraint' in str(e.orig).lower():
                return jsonify({'error': 'Запись с таким уникальным полем уже существует'}), 409
            return jsonify({'error': 'Ошибка целостности данных'}), 409
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Ошибка обновления: {str(e)}'}), 500

    @app.route(f'/{prefix}/<int:item_id>', methods=['DELETE'], endpoint=f'{prefix}_delete')
    def delete(item_id):
        """
        Удалить запись
        ---
        tags:
          - {prefix.capitalize()}
        parameters:
          - name: item_id
            in: path
            type: integer
            required: true
        responses:
          200:
            description: Запись удалена
            schema:
              type: object
              properties:
                message:
                  type: string
          404:
            description: Запись не найдена
          409:
            description: Невозможно удалить из‑за связанных записей
        """
        try:
            item = model.query.get(item_id)
            if not item:
                return jsonify({'error': f'{model_name} не найден'}), 404
            db.session.delete(item)
            db.session.commit()
            return jsonify({'message': f'{model_name} удалён'}), 200
        except IntegrityError:
            db.session.rollback()
            return jsonify({'error': 'Невозможно удалить: есть связанные записи'}), 409
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Ошибка удаления: {str(e)}'}), 500
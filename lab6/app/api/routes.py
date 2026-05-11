from ..models.user import Users
from ..models.dicts import Dicts
from ..models.words import Words
from ..schemas.user_schema import UserSchema
from ..schemas.dicts_schema import DictsSchema
from ..schemas.words_schema import WordsSchema
from ..crud.factory import register_crud_routes

import traceback
from decimal import Decimal
from flask import request, jsonify
from .. import db
from sqlalchemy import text


def register_all_routes(app):
    register_crud_routes(app, Users, UserSchema(), 'users')
    register_crud_routes(app, Dicts, DictsSchema(), 'dicts')
    register_crud_routes(app, Words, WordsSchema(), 'words')

    def _row_to_dict(row):
        result = {}
        for key, value in row._mapping.items():
            if isinstance(value, Decimal):
                result[key] = float(value)
            else:
                result[key] = value
        return result

    @app.route('/views/pair-details', methods=['GET'])
    def get_pair_details():
        """
        Детальная информация по всем парам (словарь + слово + прогресс)
        ---
        tags:
          - Views
        parameters:
          - name: page
            in: query
            type: integer
            default: 1
          - name: limit
            in: query
            type: integer
            default: 10
        responses:
          200:
            description: Успешно
            schema:
              type: object
              properties:
                items:
                  type: array
                  items:
                    type: object
                    properties:
                      pair_id: { type: integer }
                      dict_id: { type: integer }
                      dict_title: { type: string }
                      user_id: { type: integer }
                      user_name: { type: string }
                      word_id: { type: integer }
                      word_key: { type: string }
                      word_value: { type: string }
                      knowledge_level: { type: integer }
                      repetitions: { type: integer }
                      correct_in_a_row: { type: integer }
                      last_repetition: { type: string, format: date-time }
                      next_repetition: { type: string, format: date-time }
                total: { type: integer }
                page: { type: integer }
                pages: { type: integer }
                per_page: { type: integer }
          500:
            description: Внутренняя ошибка
        """
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('limit', 10, type=int)
            offset = (page - 1) * per_page

            total = db.session.execute(text("SELECT COUNT(*) FROM pair_details")).scalar()
            rows = db.session.execute(
                text("SELECT * FROM pair_details ORDER BY pair_id LIMIT :limit OFFSET :offset"),
                {'limit': per_page, 'offset': offset}
            ).fetchall()
            items = [_row_to_dict(row) for row in rows]
            return jsonify({
                'items': items,
                'total': total,
                'page': page,
                'pages': (total + per_page - 1) // per_page,
                'per_page': per_page
            }), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e), 'trace': traceback.format_exc()}), 500

    @app.route('/views/user-activity', methods=['GET'])
    def get_user_activity():
        """
        Активность пользователей (количество словарей, уникальных слов, повторений)
        ---
        tags:
          - Views
        responses:
          200:
            description: Успешно
            schema:
              type: array
              items:
                type: object
                properties:
                  id: { type: integer }
                  name: { type: string }
                  email: { type: string }
                  dicts_count: { type: integer }
                  unique_words_learned: { type: integer }
                  total_repetitions: { type: integer }
                  avg_knowledge_level: { type: number, format: float }
        """
        try:
            rows = db.session.execute(text("SELECT * FROM user_activity ORDER BY id")).fetchall()
            result = [_row_to_dict(row) for row in rows]
            return jsonify(result), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e), 'trace': traceback.format_exc()}), 500

    @app.route('/views/dict-stats', methods=['GET'])
    def get_dict_stats():
        """
        Статистика по каждому словарю (количество слов, средний уровень, повторения)
        ---
        tags:
          - Views
        responses:
          200:
            description: Успешно
            schema:
              type: array
              items:
                type: object
                properties:
                  id: { type: integer }
                  title: { type: string }
                  description: { type: string }
                  user_id: { type: integer }
                  words_count: { type: integer }
                  avg_knowledge: { type: number, format: float }
                  total_repetitions: { type: integer }
                  max_streak: { type: integer }
        """
        try:
            rows = db.session.execute(text("SELECT * FROM dict_stats ORDER BY id")).fetchall()
            result = [_row_to_dict(row) for row in rows]
            return jsonify(result), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e), 'trace': traceback.format_exc()}), 500


    @app.route('/dicts/<int:dict_id>/add-word', methods=['POST'])
    def add_word_to_dict(dict_id):
        """
        Добавить слово в словарь (вызов процедуры add_word_to_dict_p)
        ---
        tags:
          - Procedures
        parameters:
          - name: dict_id
            in: path
            type: integer
            required: true
          - name: body
            in: body
            required: true
            schema:
              type: object
              required: [key, value, topic]
              properties:
                key: { type: string }
                value: { type: string }
                topic: { type: string }
        responses:
          200:
            description: Слово успешно добавлено
            schema:
              type: object
              properties:
                message: { type: string }
          400:
            description: Ошибка (словарь не существует, слово уже есть или темы не совпадают)
          500:
            description: Внутренняя ошибка
        """
        """
        Ожидает JSON: {"key": "word_key", "value": "word_value", "topic": "topic_name"}
        """
        try:
            data = request.get_json()
            if not data or 'key' not in data or 'value' not in data or 'topic' not in data:
                return jsonify({'error': 'Missing required fields: key, value, topic'}), 400

            db.session.execute(
                text("CALL add_word_to_dict_p(:dict_id, :key, :value, :topic)"),
                {
                    'dict_id': dict_id,
                    'key': data['key'],
                    'value': data['value'],
                    'topic': data['topic']
                }
            )
            db.session.commit()
            return jsonify({'message': f'Word "{data["key"]}" added to dict {dict_id}'}), 200

        except Exception as e:
            db.session.rollback()
            error_msg = str(e).split('ERROR: ')[-1] if 'ERROR:' in str(e) else str(e)
            return jsonify(
                {'error': error_msg}), 400 if 'не существует' in error_msg or 'уже присутствует' in error_msg else 500

    @app.route('/pairs/<int:pair_id>/update-progress', methods=['POST'])
    def update_progress_endpoint(pair_id):
        """
        Обновить прогресс изучения пары (вызов функции update_progress)
        ---
        tags:
          - Procedures
        parameters:
          - name: pair_id
            in: path
            type: integer
            required: true
          - name: body
            in: body
            required: true
            schema:
              type: object
              required: [is_correct]
              properties:
                is_correct: { type: boolean }
        responses:
          200:
            description: Прогресс обновлён
            schema:
              type: object
              properties:
                message: { type: string }
          400:
            description: Неверные входные данные
          404:
            description: Прогресс для пары не найден
        """
        """
        Ожидает JSON: {"is_correct": true/false}
        """
        try:
            data = request.get_json()
            if data is None or 'is_correct' not in data:
                return jsonify({'error': 'Missing is_correct field (boolean)'}), 400

            is_correct = data['is_correct']
            db.session.execute(
                text("SELECT update_progress(:pair_id, :is_correct)"),
                {'pair_id': pair_id, 'is_correct': is_correct}
            )
            db.session.commit()
            return jsonify({'message': f'Progress updated for pair {pair_id} (correct={is_correct})'}), 200

        except Exception as e:
            db.session.rollback()
            error_msg = str(e).split('ERROR: ')[-1] if 'ERROR:' in str(e) else str(e)
            if 'не найден' in error_msg or 'not found' in error_msg.lower():
                return jsonify({'error': error_msg}), 404
            return jsonify({'error': error_msg}), 400

    @app.route('/users/<int:user_id>/stats', methods=['GET'])
    def get_user_stats(user_id):
        """
        Получить агрегированную статистику пользователя (функция get_user_stats)
        ---
        tags:
          - Procedures
        parameters:
          - name: user_id
            in: path
            type: integer
            required: true
        responses:
          200:
            description: Успешно
            schema:
              type: object
              properties:
                dicts_count: { type: integer }
                total_words: { type: integer }
                avg_knowledge_level: { type: number, format: float }
                due_words_count: { type: integer }
          404:
            description: Пользователь не найден
        """
        try:
            rows = db.session.execute(
                text("SELECT * FROM get_user_stats(:user_id)"),
                {'user_id': user_id}
            ).fetchall()
            if not rows:
                return jsonify({'error': 'User not found or no stats'}), 404

            stats = dict(rows[0]._mapping)
            for key in stats:
                if isinstance(stats[key], Decimal):
                    stats[key] = float(stats[key])
            return jsonify(stats), 200

        except Exception as e:
            db.session.rollback()
            error_msg = str(e).split('ERROR: ')[-1] if 'ERROR:' in str(e) else str(e)
            if 'не найден' in error_msg or 'not found' in error_msg.lower():
                return jsonify({'error': error_msg}), 404
            return jsonify({'error': error_msg}), 500

    @app.route('/reports/dict-stats', methods=['GET'])
    def report_dict_stats():
        """
        Агрегированные данные по словарям (средний уровень, повторения, максимальная серия)
        ---
        tags:
          - Reports
        responses:
          200:
            description: Успешно
            schema:
              type: array
              items:
                type: object
                properties:
                  id: { type: integer }
                  title: { type: string }
                  description: { type: string }
                  user_id: { type: integer }
                  words_count: { type: integer }
                  avg_knowledge: { type: number, format: float }
                  total_repetitions: { type: integer }
                  max_streak: { type: integer }
        """
        """Агрегированные данные по словарям (из представления dict_stats)"""
        try:
            rows = db.session.execute(text("SELECT * FROM dict_stats ORDER BY id")).fetchall()
            result = [_row_to_dict(row) for row in rows]
            return jsonify(result), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e)}), 500

    @app.route('/reports/top-users', methods=['GET'])
    def report_top_users():
        """
        Топ пользователей по общему количеству повторений
        ---
        tags:
          - Reports
        parameters:
          - name: limit
            in: query
            type: integer
            default: 5
            minimum: 1
            maximum: 100
            description: Количество записей в топе
        responses:
          200:
            description: Успешно
            schema:
              type: array
              items:
                type: object
                properties:
                  id: { type: integer }
                  name: { type: string }
                  email: { type: string }
                  total_repetitions: { type: integer }
                  avg_knowledge_level: { type: number, format: float }
          400:
            description: Некорректный параметр limit
        """
        """
        Топ пользователей по общему количеству повторений.
        Параметр запроса: ?limit=N (по умолчанию 5)
        """
        try:
            limit = request.args.get('limit', 5, type=int)
            rows = db.session.execute(text("""
                SELECT u.id, u.name, u.email,
                       COALESCE(SUM(pr.repetitions), 0) AS total_repetitions,
                       COALESCE(AVG(pr.knowledge_level), 0) AS avg_knowledge_level
                FROM users u
                LEFT JOIN dicts d ON u.id = d.user_id
                LEFT JOIN pairs p ON d.id = p.dict_id
                LEFT JOIN progress pr ON p.id = pr.pair_id
                GROUP BY u.id
                ORDER BY total_repetitions DESC
                LIMIT :limit
            """), {'limit': limit}).fetchall()
            result = []
            for row in rows:
                r = dict(row._mapping)
                for key in r:
                    if isinstance(r[key], Decimal):
                        r[key] = float(r[key])
                result.append(r)
            return jsonify(result), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e)}), 500
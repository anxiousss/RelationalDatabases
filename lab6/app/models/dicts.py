from .. import db

class Dicts(db.Model):
    __tablename__ = 'dicts'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    title = db.Column(db.Text, nullable=False)
    description = db.Column(db.Text, nullable=False)

    __table_args__ = (
        db.UniqueConstraint(user_id, title, name='unique_user_dict'),
    )
    
from .. import db

class Words(db.Model):
    __tablename__ = 'words'
    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.Text, nullable=False)
    value = db.Column(db.Text, nullable=False)
    __table_args__ = (
        db.UniqueConstraint(key, value, name='unique_key'),
    )

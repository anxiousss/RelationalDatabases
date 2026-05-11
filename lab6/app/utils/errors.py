from flask import jsonify


def handle_generic(error):
    return jsonify({'error': 'Internal server error'}), 500

def handle_404(error):
    return jsonify({'error': 'Endpoint not found'}), 404
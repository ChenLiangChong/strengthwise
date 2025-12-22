from dataclasses import dataclass, asdict
from flask import Flask, request, jsonify
from flask_cors import CORS

# User Class and Database
@dataclass
class User:
    id: int
    name: str
    email: str
    bio: str

    def update(self, data):
        self.name = data.get('name', self.name)
        self.email = data.get('email', self.email)
        self.bio = data.get('bio', self.bio)

# Mock database represented as a dictionary
users_db = dict()

# CRUD Functions
def create_user(id, name, email, bio):
    """
    Creates a new user and adds it to the mock database.

    Args:
        id (int): Unique identifier for the user.
        name (str): Name of the user.
        email (str): Email address of the user.
        bio (str): Bio of the user.

    Returns:
        User: The created User instance.

    Raises:
        ValueError: If a user with the given ID already exists.
    """
    if id in users_db:
        raise ValueError(f"User with ID {id} already exists.")

    user = User(id, name, email, bio)
    users_db[id] = user
    return user

def get_user_by_id(user_id):
    """
    Retrieves a user by their ID.

    Args:
        user_id (int): The ID of the user to retrieve.

    Returns:
        User or None: The User instance if found, else None.
    """
    return users_db.get(user_id)

def update_user(user_id, data):
    """
    Updates an existing user's details.

    Args:
        user_id (int): The ID of the user to update.
        data (dict): A dictionary containing the fields to update.

    Returns:
        User: The updated User instance.

    Raises:
        ValueError: If the user does not exist.
    """
    user = get_user_by_id(user_id)
    if user:
        user.update(data)
        return user
    raise ValueError(f"User with ID {user_id} not found.")

def list_users():
    """
    Lists all users in the mock database.

    Returns:
        list: A list of User instances.
    """
    return list(users_db.values())

# Utility Functions
def seed_mock_db():
    """
    Seeds the mock database with initial users.
    """
    create_user(0, "Alice Smith", "alice@example.com", "Software Developer from NY.")
    create_user(1, "Bob Johnson", "bob@example.com", "Graphic Designer from CA.")
    create_user(2, "Charlie Lee", "charlie@example.com", "Data Scientist from TX.")

# Flask Application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize Mock Database with Seed Data
seed_mock_db()

@app.route('/api/user/<int:user_id>', methods=['GET'])
def api_get_user(user_id):
    """
    Retrieves a specific user by ID.
    """
    user = get_user_by_id(user_id)
    if user:
        return jsonify(asdict(user)), 200
    else:
        return jsonify({'error': 'User not found.'}), 404

@app.route('/api/user/<int:user_id>', methods=['PUT'])
def api_update_user(user_id):
    """
    Updates an existing user's details.
    """
    data = request.get_json()
    if data is None:
        return jsonify({'error': 'No data provided for update.'}), 400

    try:
        user = update_user(user_id, data)
        return jsonify(asdict(user)), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 404

if __name__ == '__main__':
    app.run(debug=True)

@app.route('/user/profile', methods=['GET'])
@jwt_required
def get_user_profile():
    """Get current user profile including preferences."""
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return jsonify({"error": "Authorization header missing"}), 401
    
    try:
        access_token = auth_header.split()[1]
        payload = pyjwt.decode(access_token, options={"verify_signature": False})
        user_id = payload.get('user_id')
        
        db = Database()
        if not db.connect():
            return jsonify({"error": "Database connection failed"}), 500
            
        try:
            query = "SELECT id, name, email, profile_picture_url, is_verified, preferences FROM users WHERE id = %s"
            users = db.execute_query(query, (user_id,))
            
            if not users:
                return jsonify({"error": "User not found"}), 404
                
            user = users[0]
            aes_key = get_or_create_user_aes_key(user['id'], db)
            
            return jsonify({
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": resolve_stored_url(user['profile_picture_url'], "profilePictures"),
                    "aes_key": aes_key,
                    "preferences": user.get('preferences')
                }
            }), 200
            
        finally:
            db.disconnect()
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

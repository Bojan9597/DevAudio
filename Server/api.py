from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
from werkzeug.security import generate_password_hash, check_password_hash
from database import Database
from badge_service import BadgeService

import re
import datetime
import update_server_ip # Auto-update DB IP on startup

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# Base URL for external access (Ngrok or Local IP)
# Dynamically set based on current machine IP
current_ip = update_server_ip.get_local_ip()
BASE_URL = f"http://{current_ip}:5000/"
print(f"Server initialized with BASE_URL: {BASE_URL}")
# Auto-update Flutter Client Configuration
update_server_ip.update_flutter_client(current_ip)

# ... existing build_category_tree ...

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    confirm_password = data.get('confirm_password')

    if not all([name, email, password, confirm_password]):
        return jsonify({"error": "Missing fields"}), 400

    if password != confirm_password:
        return jsonify({"error": "Passwords do not match"}), 400

    # Password complexity check
    # At least 8 chars, 1 uppercase, 1 number, 1 special char
    if not re.match(r'''^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|~-]).{8,}$''', password):
        return jsonify({
            "error": "Password must be at least 8 characters long and include an uppercase letter, a number, and a special character"
        }), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user exists in main table
        check_query = "SELECT id FROM users WHERE email = %s"
        existing = db.execute_query(check_query, (email,))
        if existing:
            return jsonify({"error": "Email already registered"}), 409

        # Hash password
        hashed_pw = generate_password_hash(password)
        
        # Generate Verification Code
        import random
        verification_code = str(random.randint(100000, 999999))
        
        # Insert/Update pending user
        # We use REPLACE INTO to handle retries (e.g. user didn't get code first time)
        insert_query = "REPLACE INTO pending_users (name, email, password_hash, verification_code) VALUES (%s, %s, %s, %s)"
        cursor = db.connection.cursor()
        cursor.execute(insert_query, (name, email, hashed_pw, verification_code))
        db.connection.commit()
        cursor.close()
        
        # Mock sending email
        print("--------------------------------------------------")
        print(f"Verification code for {email}: {verification_code}")
        print("--------------------------------------------------")
        
        # Write to file for easier access
        with open("verification_code.txt", "w") as f:
            f.write(f"Verification code for {email}: {verification_code}")


        return jsonify({"message": "Verification code sent", "email": email}), 202


    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/verify-email', methods=['POST'])
def verify_email():
    data = request.get_json()
    email = data.get('email')
    code = data.get('code')
    
    if not all([email, code]):
        return jsonify({"error": "Missing email or code"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Check code in pending_users
        query = "SELECT * FROM pending_users WHERE email = %s"
        pending_users = db.execute_query(query, (email,))
        
        if not pending_users:
             return jsonify({"error": "Registration not found or already verified"}), 404
             
        pending_user = pending_users[0]
        if pending_user['verification_code'] == code:
            # Move to users table
            insert_query = "INSERT INTO users (name, email, password_hash, is_verified) VALUES (%s, %s, %s, TRUE)"
            cursor = db.connection.cursor()
            cursor.execute(insert_query, (pending_user['name'], pending_user['email'], pending_user['password_hash']))
            db.connection.commit()
            user_id = cursor.lastrowid
            
            # Delete from pending
            delete_query = "DELETE FROM pending_users WHERE email = %s"
            cursor.execute(delete_query, (email,))
            db.connection.commit()
            cursor.close()
            
            # Return login data
            return jsonify({
                "message": "Verification successful",
                "user": {
                    "id": user_id,
                    "name": pending_user['name'],
                    "email": pending_user['email'],
                     "profile_picture_url": None 
                }
            }), 200
        else:
            return jsonify({"error": "Invalid verification code"}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not all([email, password]):
        return jsonify({"error": "Missing fields"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Fetch user
        query = "SELECT id, name, email, password_hash, profile_picture_url, is_verified FROM users WHERE email = %s"
        users = db.execute_query(query, (email,))
        
        if not users:
            return jsonify({"error": "Invalid credentials"}), 401
            
        user = users[0]
        
        if not user.get('is_verified', 1): # Default to 1 (True) for old users if column was just added
             # In our case we set default 0 but updated old ones to 1.
             # If user is not verified:
             if user['is_verified'] == 0:
                 return jsonify({"error": "Email not verified", "email": email}), 403
        
        # Verify password
        if check_password_hash(user['password_hash'], password):
            return jsonify({
                "message": "Login successful",
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": user['profile_picture_url']
                }
            }), 200
        else:
            return jsonify({"error": "Invalid credentials"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/change-password', methods=['POST'])
def change_password():
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not all([user_id, current_password, new_password]):
        return jsonify({"error": "Missing fields"}), 400

    # Password complexity check for new password
    if not re.match(r'''^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|~-]).{8,}$''', new_password):
        return jsonify({
            "error": "New password must be at least 8 characters long and include an uppercase letter, a number, and a special character"
        }), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Fetch user
        query = "SELECT password_hash FROM users WHERE id = %s"
        users = db.execute_query(query, (user_id,))
        
        if not users:
            return jsonify({"error": "User not found"}), 404
            
        user = users[0]
        
        # Verify current password
        if not check_password_hash(user['password_hash'], current_password):
            return jsonify({"error": "Incorrect current password"}), 401
            
        # Update with new password
        new_hash = generate_password_hash(new_password)
        update_query = "UPDATE users SET password_hash = %s WHERE id = %s"
        db.execute_query(update_query, (new_hash, user_id))
        
        return jsonify({"message": "Password updated successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/google-login', methods=['POST'])
def google_login():
    data = request.get_json()
    email = data.get('email')
    name = data.get('name')
    # google_id = data.get('google_id') # Optional, for syncing

    if not email:
        return jsonify({"error": "Email required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user exists
        query = "SELECT id, name, email, profile_picture_url FROM users WHERE email = %s"
        users = db.execute_query(query, (email,))

        if users:
            # Login existing
            user = users[0]
            return jsonify({
                "message": "Login successful",
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": user['profile_picture_url']
                }
            }), 200
        else:
            # Register new user (with dummy password hash since it's Google auth)
            # Or make password nullable. For now, we set a placeholder hash.
            dummy_hash = generate_password_hash("google_auth_placeholder")
            
            insert_query = "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)"
            cursor = db.connection.cursor()
            cursor.execute(insert_query, (name or "Google User", email, dummy_hash))
            db.connection.commit()
            user_id = cursor.lastrowid
            cursor.close()

            return jsonify({
                "message": "User registered via Google",
                "user": {
                    "id": user_id,
                    "name": name,
                    "email": email,
                    "profile_picture_url": None
                }
            }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

# Configure upload folder
basedir = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = os.path.join(basedir, 'static', 'profilePictures')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/profilePictures/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/upload-profile-picture', methods=['POST'])
def upload_profile_picture():
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({"error": "User ID is required"}), 400

    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    if file and allowed_file(file.filename):
        db = Database()
        if not db.connect():
             return jsonify({"error": "Database connection failed"}), 500

        try:
            # 1. Get user email to name the file
            email_query = "SELECT email FROM users WHERE id = %s"
            users = db.execute_query(email_query, (user_id,))
            if not users:
                return jsonify({"error": "User not found"}), 404
            
            user_email = users[0]['email']
            
            # 2. Create filename from email
            # Secure the email to be safe for filesystem (replace @ with _, etc if needed, but strict secure_filename might strip too much)
            # secure_filename("test@example.com") -> "test_example.com" usually. 
            # Let's keep it simple and safe.
            file_ext = file.filename.rsplit('.', 1)[1].lower()
            safe_email_name = secure_filename(user_email) # e.g. test_example_com
            new_filename = f"{safe_email_name}.{file_ext}"

            file_path = os.path.join(app.config['UPLOAD_FOLDER'], new_filename)
            file.save(file_path)
            
            # 3. Save relative path to DB
            # The path should be consistent with the route that serves it: /profilePictures/<filename>
            # Frontend will append this to base URL.
            relative_path = f"profilePictures/{new_filename}"
            
            full_url = f"{request.host_url}{relative_path}"
            
            update_query = "UPDATE users SET profile_picture_url = %s WHERE id = %s"
            db.execute_query(update_query, (relative_path, user_id))
            
            return jsonify({"message": "Profile picture updated", "url": full_url, "path": relative_path}), 200

        except Exception as e:
            return jsonify({"error": str(e)}), 500
        finally:
            db.disconnect()
            
    return jsonify({"error": "File type not allowed"}), 400

def build_category_tree(categories, parent_id=None):
    """
    Recursively builds a tree of categories.
    categories is a list of dicts (rows) from the DB.
    """
    branch = []
    for cat in categories:
        # Check if this category is a child of the current parent_id
        # In the DB, parent_id might be None for root, or an int.
        # Python's None == None is True.
        
        # We need to handle the fact that execute_query returns dicts
        # assuming 'id', 'name', 'parent_id' are keys.
        
        row_parent_id = cat.get('parent_id')
        
        if row_parent_id == parent_id:
            children = build_category_tree(categories, cat['id'])
            
            # Construct dictionary matching the Flutter model expectations if possible
            # Flutter model uses 'id' (string) and 'title'. 
            # We use the 'slug' from DB as the 'id' for the app.
            
            node = {
                'id': cat['slug'], # Use slug (e.g. 'python') as ID
                'title': cat['name'],
                'children': children,
                # 'hasBooks': ... we could check this if we had books
            }
            branch.append(node)
            
    return branch

@app.route('/categories', methods=['GET'])
def get_categories():
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Fetch all categories
        result = db.execute_query("SELECT id, name, slug, parent_id FROM categories ORDER BY id ASC")
        
        if result is None:
             return jsonify({"error": "Failed to fetch categories"}), 500

        # Build tree
        tree = build_category_tree(result)
        
        return jsonify(tree)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/playlist/<int:book_id>', methods=['GET'])
def get_playlist(book_id):
    user_id = request.args.get('user_id')
    
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    try:
        if user_id:
             query = """
                SELECT p.*, 
                       CASE WHEN uct.id IS NOT NULL THEN TRUE ELSE FALSE END as is_completed,
                       COALESCE(utp.position_seconds, 0) as last_position
                FROM playlist_items p
                LEFT JOIN user_completed_tracks uct ON p.id = uct.track_id AND uct.user_id = %s
                LEFT JOIN user_track_progress utp ON p.id = utp.playlist_item_id AND utp.user_id = %s
                WHERE p.book_id = %s 
                ORDER BY p.track_order ASC
             """
             result = db.execute_query(query, (user_id, user_id, book_id))

        else:
             query = "SELECT *, FALSE as is_completed FROM playlist_items WHERE book_id = %s ORDER BY track_order ASC"
             result = db.execute_query(query, (book_id,))
             
        if result:
            # Normalize boolean (MySQL returns 1/0)
            for item in result:
                item['is_completed'] = bool(item.get('is_completed', 0))
                
            # Check for quiz containing questions
            quiz_exists = False
            q_query = """
                SELECT q.id 
                FROM quizzes q
                INNER JOIN quiz_questions qq ON q.id = qq.quiz_id
                WHERE q.book_id = %s AND q.playlist_item_id IS NULL
                LIMIT 1
            """
            # Reuse DB connection? Yes.
            q_res = db.execute_query(q_query, (book_id,))
            if q_res:
                quiz_exists = True
                
            # Check if quiz is passed by THIS user
            quiz_passed = False
            if quiz_exists and user_id:
               # We need quiz_id. The previous query just checked existence.
               # Let's get quiz_id
               qid_query = "SELECT id FROM quizzes WHERE book_id = %s"
               qid_res = db.execute_query(qid_query, (book_id,))
               if qid_res:
                   quiz_id = qid_res[0]['id']
                   pass_query = "SELECT is_passed FROM user_quiz_results WHERE user_id = %s AND quiz_id = %s ORDER BY completed_at DESC LIMIT 1"
                   pass_res = db.execute_query(pass_query, (user_id, quiz_id))
                   if pass_res and pass_res[0]['is_passed']:
                       quiz_passed = True

            # Check for Track Quizzes
            track_quizzes = {}
            if user_id:
                # Get all quizzes for this book's tracks
                # Map playlist_item_id -> {has_quiz, passed}
                tq_query = """
                    SELECT q.playlist_item_id, q.id as quiz_id,
                           (SELECT is_passed FROM user_quiz_results uqr WHERE uqr.quiz_id = q.id AND uqr.user_id = %s ORDER BY completed_at DESC LIMIT 1) as is_passed
                    FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NOT NULL
                """
                tq_res = db.execute_query(tq_query, (user_id, book_id))
                if tq_res:
                    for row in tq_res:
                        track_quizzes[str(row['playlist_item_id'])] = {
                            "has_quiz": True,
                            "is_passed": bool(row['is_passed'])
                        }
            else:
                # Just check existence
                tq_query = "SELECT playlist_item_id FROM quizzes WHERE book_id = %s AND playlist_item_id IS NOT NULL"
                tq_res = db.execute_query(tq_query, (book_id,))
                if tq_res:
                    for row in tq_res:
                        track_quizzes[str(row['playlist_item_id'])] = {
                           "has_quiz": True,
                           "is_passed": False
                        }
                
            return jsonify({
                "tracks": result, 
                "has_quiz": quiz_exists, 
                "quiz_passed": quiz_passed,
                "track_quizzes": track_quizzes 
            })
        
        # Fallback for "Single Book" treated as Playlist
        book_query = "SELECT title, audio_path, duration_seconds FROM books WHERE id = %s"
        book_res = db.execute_query(book_query, (book_id,))
        if book_res:
            book = book_res[0]
            audio_path = book['audio_path']
            # Ensure Full URL
            if audio_path and not audio_path.startswith('http'):
                 if not audio_path.startswith('static/'):
                     audio_path = f"static/AudioBooks/{audio_path}"
                 audio_path = f"{BASE_URL}{audio_path}"
            
            # Check if book is "read" if it's a single file?
            # We can check user_books.is_read
            is_completed = False
            if user_id:
                ub_query = "SELECT is_read FROM user_books WHERE user_id = %s AND book_id = %s"
                ub_res = db.execute_query(ub_query, (user_id, book_id))
                if ub_res:
                    is_completed = bool(ub_res[0]['is_read'])

            synthetic_item = {
                "id": -1, # Virtual ID
                "book_id": book_id,
                "file_path": audio_path,
                "title": book['title'],
                "duration_seconds": book['duration_seconds'],
                "track_order": 0,
                "is_completed": is_completed
            }
            
            # Check if quiz exists
            quiz_exists = False
            q_query = "SELECT id FROM quizzes WHERE book_id = %s"
            q_res = db.execute_query(q_query, (book_id,))
            if q_res:
                quiz_exists = True

            return jsonify({"tracks": [synthetic_item], "has_quiz": quiz_exists})
            
        return jsonify({"tracks": [], "has_quiz": False})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/quiz', methods=['POST'])
def save_quiz():
    data = request.get_json()
    book_id = data.get('book_id')
    playlist_item_id = data.get('playlist_item_id') # Optional
    questions = data.get('questions') # List of dicts
    
    if not all([book_id, questions]):
        return jsonify({"error": "Missing book_id or questions"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Check if quiz exists, if so, we can replace it or append.
        # Simplest: Delete old, create new.
        # But we need to handle the quiz_id.
        
        # 1. Get or Create Quiz ID
        cursor = db.connection.cursor()
        
        check_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            check_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
             check_query += " AND playlist_item_id IS NULL"
             
        cursor.execute(check_query, tuple(params))
        res = cursor.fetchone()
        
        if res:
            quiz_id = res[0]
            # Clear old questions
            cursor.execute("DELETE FROM quiz_questions WHERE quiz_id = %s", (quiz_id,))
        else:
            if playlist_item_id:
                ins_q = "INSERT INTO quizzes (book_id, playlist_item_id) VALUES (%s, %s)"
                cursor.execute(ins_q, (book_id, playlist_item_id))
            else:
                ins_q = "INSERT INTO quizzes (book_id) VALUES (%s)"
                cursor.execute(ins_q, (book_id,))
                
            quiz_id = cursor.lastrowid
            
        # 2. Insert Questions
        q_insert = """
            INSERT INTO quiz_questions 
            (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, order_index)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        for idx, q in enumerate(questions):
            cursor.execute(q_insert, (
                quiz_id,
                q['question'],
                q['options'][0],
                q['options'][1],
                q['options'][2],
                q['options'][3],
                q['correctAnswer'], # Expecting 'A', 'B', 'C', 'D'
                idx
            ))
            
        db.connection.commit()
        cursor.close()
        
        return jsonify({"message": "Quiz saved successfully"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()
        
@app.route('/quiz/<int:book_id>', methods=['GET'])
def get_quiz(book_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get Quiz ID
        playlist_item_id = request.args.get('playlist_item_id')
        
        q_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            q_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
            q_query += " AND playlist_item_id IS NULL"
            
        q_res = db.execute_query(q_query, tuple(params))
        
        if not q_res:
            return jsonify([]) # No quiz
            
        quiz_id = q_res[0]['id']
        
        # Get Questions
        ques_query = """
            SELECT question_text, option_a, option_b, option_c, option_d, correct_answer
            FROM quiz_questions 
            WHERE quiz_id = %s 
            ORDER BY order_index ASC
        """
        questions = db.execute_query(ques_query, (quiz_id,))
        
        # Format for frontend
        formatted = []
        for q in questions:
            formatted.append({
                "question": q['question_text'],
                "options": [q['option_a'], q['option_b'], q['option_c'], q['option_d']],
                "correctAnswer": q['correct_answer']
            })
            
        return jsonify(formatted)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


@app.route('/books', methods=['GET'])
def get_books():
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 5, type=int)
        search_query = request.args.get('q', '', type=str)
        
        offset = (page - 1) * limit

        params = []
        # Updated query to check for playlist items existence
        base_select = """
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug, 
                   u.name as posted_by_name, b.description, b.price, b.posted_by_user_id,
                   (SELECT COUNT(*) FROM playlist_items WHERE book_id = b.id) as playlist_count
            FROM books b 
            LEFT JOIN categories c ON b.primary_category_id = c.id
            LEFT JOIN users u ON b.posted_by_user_id = u.id
        """
        
        if search_query:
             query = base_select + " WHERE b.title LIKE %s"
             params.append(f"%{search_query}%")
        else:
            query = base_select
            
        # Add ordering (optional but good for consistency)
        query += " ORDER BY b.id DESC" 
        
        query += " LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        books_result = db.execute_query(query, tuple(params))
        
        books = []
        if books_result:
            for row in books_result:
                book_id = row['id']
                
                # Fetch subcategory slugs
                sub_query = """
                    SELECT c.slug 
                    FROM book_categories bc
                    JOIN categories c ON bc.category_id = c.id
                    WHERE bc.book_id = %s
                """
                sub_result = db.execute_query(sub_query, (book_id,))
                subcategory_ids = [sub['slug'] for sub in sub_result] if sub_result else []
                
                # Construct full Audio URL if relative
                audio_path = row['audio_path']
                if audio_path and not audio_path.startswith('http'):
                     if not audio_path.startswith('static/'):
                         audio_path = f"static/AudioBooks/{audio_path}"
                     audio_path = f"{BASE_URL}{audio_path}"

                # Construct full Cover URL if relative
                cover_path = row['cover_image_path']
                if cover_path and not cover_path.startswith('http'):
                     if not cover_path.startswith('static/'):
                         cover_path = f"static/BookCovers/{cover_path}"
                     cover_path = f"{BASE_URL}{cover_path}"
                
                books.append({
                    "id": str(book_id),
                    "title": row['title'],
                    "author": row['author'],
                    "audioUrl": audio_path,
                    "coverUrl": cover_path,
                    "categoryId": row['category_slug'] or "", 
                    "subcategoryIds": subcategory_ids,
                    "postedBy": row['posted_by_name'] or "Unknown",
                    "description": row['description'],
                    "price": float(row['price']) if row['price'] else 0.0,
                    "postedByUserId": str(row['posted_by_user_id']),
                    "isPlaylist": row['playlist_count'] > 0
                })
        
        return jsonify(books)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user-books/<int:user_id>', methods=['GET'])
def get_user_books(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Fetch purchased book IDs
        query = "SELECT book_id FROM user_books WHERE user_id = %s"
        result = db.execute_query(query, (user_id,))
        
        book_ids = [row['book_id'] for row in result] if result else []
        return jsonify(book_ids)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/buy-book', methods=['POST'])
def buy_book():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if already owned
        check_query = "SELECT id FROM user_books WHERE user_id = %s AND book_id = %s"
        existing = db.execute_query(check_query, (user_id, book_id))
        
        if existing:
            return jsonify({"message": "Book already purchased"}), 200

        # Insert purchase
        insert_query = "INSERT INTO user_books (user_id, book_id) VALUES (%s, %s)"
        db.execute_query(insert_query, (user_id, book_id))

        new_badges = []
        try:
            # Check for new badges
            badge_service = BadgeService(db.connection)
            new_badges = badge_service.check_badges(user_id)
        except Exception as e:
            print(f"Error checking badges in buy_book: {e}")
            import traceback
            traceback.print_exc()

        return jsonify({"message": "Book purchased successfully", "new_badges": new_badges}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/complete-track', methods=['POST'])
def complete_track():
    data = request.get_json()
    user_id = data.get('user_id')
    track_id = data.get('track_id')
    
    if not all([user_id, track_id]):
        return jsonify({"error": "Missing user_id or track_id"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # 1. Mark track as completed
        query = "INSERT IGNORE INTO user_completed_tracks (user_id, track_id) VALUES (%s, %s)"
        db.execute_query(query, (user_id, track_id))
        
        # 2. Check if ALL tracks for this book are completed
        # First get book_id
        book_query = "SELECT book_id FROM playlist_items WHERE id = %s"
        book_res = db.execute_query(book_query, (track_id,))
        
        is_book_completed = False
        if book_res:
            book_id = book_res[0]['book_id']
            
            # Count total tracks
            count_query = "SELECT COUNT(*) as total FROM playlist_items WHERE book_id = %s"
            total_tracks = db.execute_query(count_query, (book_id,))[0]['total']
            
            # Count completed tracks for this user & book
            completed_query = """
                SELECT COUNT(*) as completed 
                FROM user_completed_tracks uct
                JOIN playlist_items pi ON uct.track_id = pi.id
                WHERE uct.user_id = %s AND pi.book_id = %s
            """
            completed_tracks = db.execute_query(completed_query, (user_id, book_id))[0]['completed']
            
            if completed_tracks >= total_tracks:
                is_book_completed = True
                print(f"User {user_id} completed book {book_id} (All {completed_tracks} tracks)")
                
                # Mark book as read
                update_read = "UPDATE user_books SET is_read = TRUE, last_accessed_at = CURRENT_TIMESTAMP WHERE user_id = %s AND book_id = %s"
                db.execute_query(update_read, (user_id, book_id))
                
                # Check Badges (since book is now read)
                # Check Badges (since book is now read)
                try:
                    badge_service = BadgeService(db.connection)
                    badge_service.check_badges(user_id)
                except Exception as b_err:
                    print(f"Badge check error: {b_err}")

        return jsonify({"message": "Track marked as completed", "is_book_completed": is_book_completed}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/update-progress', methods=['POST'])
def update_progress():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')
    position = data.get('position_seconds')
    total_duration = data.get('duration') # Optional, from player
    playlist_item_id = data.get('playlist_item_id') # Optional, for track progress

    if not all([user_id, book_id, position is not None]):
        return jsonify({"error": "Missing fields"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        check_query = "SELECT id FROM user_books WHERE user_id = %s AND book_id = %s"
        existing = db.execute_query(check_query, (user_id, book_id))
        
        if existing:
            # Duration Logic
            duration_query = "SELECT duration_seconds FROM books WHERE id = %s"
            duration_result = db.execute_query(duration_query, (book_id,))
            db_duration = duration_result[0]['duration_seconds'] if duration_result else 0
            
            if db_duration == 0 and total_duration and total_duration > 0:
                # Only update duration if it's NOT a playlist (playlists usually have 0 or sum)
                # For now we let it update, but we won't use it for is_read if it's a playlist
                print(f"Updating duration for book {book_id} to {total_duration}")
                update_book_query = "UPDATE books SET duration_seconds = %s WHERE id = %s"
                db.execute_query(update_book_query, (total_duration, book_id))
                db_duration = total_duration

            # Check if Playlist
            count_pl_query = "SELECT COUNT(*) as c FROM playlist_items WHERE book_id = %s"
            is_playlist = db.execute_query(count_pl_query, (book_id,))[0]['c'] > 0

            # Completion Check (95% rule) - ONLY for non-playlists
            # Playlists are marked read only via /complete-track when all items are done
            is_read = False
            if not is_playlist and db_duration > 0 and position >= (db_duration * 0.95):
                is_read = True
            
            # Update user_books
            update_sql = "UPDATE user_books SET last_played_position_seconds = %s, last_accessed_at = CURRENT_TIMESTAMP"
            params = [position]
            
            if is_read:
                update_sql += ", is_read = TRUE"
            
            if playlist_item_id:
                update_sql += ", current_playlist_item_id = %s"
                params.append(playlist_item_id)

            update_sql += " WHERE user_id = %s AND book_id = %s"
            params.extend([user_id, book_id])
            
            db.execute_query(update_sql, tuple(params))
            
            # Update user_track_progress if playlist item
            if playlist_item_id:
                track_upd_query = """
                    INSERT INTO user_track_progress (user_id, book_id, playlist_item_id, position_seconds)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE position_seconds = VALUES(position_seconds), updated_at = CURRENT_TIMESTAMP
                """
                db.execute_query(track_upd_query, (user_id, book_id, playlist_item_id, position))

            
            # Log to playback_history (History Log)
            # We record a checkpoint. 'played_seconds' here represents the position reached.
            # Ideally this table would track sessions (start/end/duration), but for now we log checkpoints.
            history_query = """
                INSERT INTO playback_history (user_id, book_id, start_time, end_time, played_seconds)
                VALUES (%s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, %s)
            """
            db.execute_query(history_query, (user_id, book_id, position))
            
            # Check for new badges
            badge_service = BadgeService(db.connection)
            new_badges = badge_service.check_badges(user_id)
            
            return jsonify({"message": "Progress updated", "is_read": is_read, "new_badges": new_badges}), 200
        else:
            return jsonify({"error": "Book not found in library"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user-stats/<int:user_id>', methods=['GET'])
def get_user_stats(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Total time listening (sum of last positions)
        # Note: This is an approximation. Ideally we sum logic from playback_history sessions, 
        # but user likely wants "total progress" across books.
        time_query = "SELECT SUM(last_played_position_seconds) as total_seconds FROM user_books WHERE user_id = %s"
        time_result = db.execute_query(time_query, (user_id,))
        total_seconds = int(time_result[0]['total_seconds'] or 0)
        
        # Books completed
        read_query = "SELECT COUNT(*) as completed_count FROM user_books WHERE user_id = %s AND is_read = TRUE"
        read_result = db.execute_query(read_query, (user_id,))
        completed_count = read_result[0]['completed_count']
        
        return jsonify({
            "total_listening_time_seconds": total_seconds,
            "books_completed": completed_count
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()



@app.route('/listen-history/<int:user_id>', methods=['GET'])
def get_listen_history(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Fetch books that have been started (position > 0) ordered by recent access
        query = """
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug, 
                   ub.last_played_position_seconds, b.duration_seconds, ub.last_accessed_at
            FROM user_books ub
            JOIN books b ON ub.book_id = b.id
            LEFT JOIN categories c ON b.primary_category_id = c.id
            WHERE ub.user_id = %s AND ub.last_played_position_seconds > 0
            ORDER BY ub.last_accessed_at DESC
        """
        result = db.execute_query(query, (user_id,))
        
        history = []
        if result:
            for row in result:
                # Construct full Cover URL if relative
                cover_path = row['cover_image_path']
                if cover_path and not cover_path.startswith('http'):
                     if not cover_path.startswith('static/'):
                         cover_path = f"static/BookCovers/{cover_path}"
                     cover_path = f"{BASE_URL}{cover_path}"

                # Construct full Audio URL if relative
                audio_path = row['audio_path']
                if audio_path and not audio_path.startswith('http'):
                     if not audio_path.startswith('static/'):
                         audio_path = f"static/AudioBooks/{audio_path}"
                     audio_path = f"{BASE_URL}{audio_path}"

                history.append({
                    "id": str(row['id']),
                    "title": row['title'],
                    "author": row['author'],
                    "audioUrl": audio_path,
                    "coverUrl": cover_path,
                    "categoryId": row['category_slug'] or "",
                    "lastPosition": row['last_played_position_seconds'],
                    "duration": row['duration_seconds'],
                    "lastAccessed": str(row['last_accessed_at'])
                })
                
        return jsonify(history)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/book-status/<int:user_id>/<int:book_id>', methods=['GET'])
def get_book_status(user_id, book_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        playlist_item_id = request.args.get('playlist_item_id')
        
        if playlist_item_id:
            # Fetch track specific progress
            query = "SELECT position_seconds FROM user_track_progress WHERE user_id = %s AND playlist_item_id = %s"
            result = db.execute_query(query, (user_id, playlist_item_id))
            if result:
                 return jsonify({"position_seconds": result[0]['position_seconds']}), 200
            else:
                 return jsonify({"position_seconds": 0}), 200
        else:
            # Fetch global book progress
            query = "SELECT last_played_position_seconds, current_playlist_item_id FROM user_books WHERE user_id = %s AND book_id = %s"
            result = db.execute_query(query, (user_id, book_id))
            
            if result:
                return jsonify({
                    "position_seconds": result[0]['last_played_position_seconds'],
                    "current_playlist_item_id": result[0].get('current_playlist_item_id')
                }), 200
            else:
                return jsonify({"position_seconds": 0, "current_playlist_item_id": None}), 200 # Not started/owned
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "message": "Audiobooks API is running"})

@app.route('/badges/<int:user_id>', methods=['GET'])
def get_user_badges(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        badge_service = BadgeService(db.connection)
        badges = badge_service.get_all_badges_with_progress(user_id)
        return jsonify(badges)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites', methods=['POST'])
def add_favorite():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        query = "INSERT IGNORE INTO favorites (user_id, book_id) VALUES (%s, %s)"
        db.execute_query(query, (user_id, book_id))
        return jsonify({"message": "Added to favorites"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites', methods=['DELETE'])
def remove_favorite():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        query = "DELETE FROM favorites WHERE user_id = %s AND book_id = %s"
        db.execute_query(query, (user_id, book_id))
        return jsonify({"message": "Removed from favorites"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites/<int:user_id>', methods=['GET'])
def get_favorites(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Use a JOIN to optionally ensure books exist if we went with No FK
        query = "SELECT book_id FROM favorites WHERE user_id = %s"
        results = db.execute_query(query, (user_id,))
        favorites = [row['book_id'] for row in results]
        return jsonify(favorites), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/upload_book', methods=['POST'])
def upload_book():
    try:
        title = request.form.get('title')
        author = request.form.get('author')
        category_id = request.form.get('category_id') 
        user_id = request.form.get('user_id')
        description = request.form.get('description', '')
        price = request.form.get('price', 0.0)

        if not all([title, author, category_id, user_id]):
             return jsonify({"error": "Missing required fields"}), 400

        # Lookup numeric Category ID
        cat_query = "SELECT id FROM categories WHERE slug = %s"
        db = Database()
        if not db.connect():
             return jsonify({"error": "Database error"}), 500
        
        cats = db.execute_query(cat_query, (category_id,))
        if not cats:
             if category_id.isdigit():
                 numeric_cat_id = int(category_id)
             else:
                 return jsonify({"error": f"Invalid category: {category_id}"}), 400
        else:
            numeric_cat_id = cats[0]['id']

        # Check for files
        audio_files = request.files.getlist('audio')
        if not audio_files or (len(audio_files) == 1 and audio_files[0].filename == ''):
            db.disconnect()
            return jsonify({"error": "No audio files provided"}), 400

        # Base directories
        base_dir = os.path.dirname(os.path.abspath(__file__))
        static_dir = os.path.join(base_dir, 'static')
        
        # Audio Path & Playlist Logic
        # If 1 file -> Standard behavior (save to AudioBooks/filename)
        # If >1 file -> Playlist behavior (save to AudioBooks/timestamp_title/filename)
        
        is_playlist = len(audio_files) > 1
        
        main_audio_path = "" # For books table (first file or empty?)
        # Strategy: 
        # If Playlist: main_audio_path can be null or point to first file as fallback.
        # Let's verify schema: audio_path is VARCHAR, maybe Not Null? 
        # Usually it is allowed to be empty if we relax it, but let's point to first track.
        
        timestamp_prefix = int(datetime.datetime.now().timestamp())
        
        saved_files_info = [] # (filename, full_db_path)

        if is_playlist:
            # Create Folder: timestamp_safeTitle
            safe_title = secure_filename(title)
            folder_name = f"{timestamp_prefix}_{safe_title}"
            book_folder_path = os.path.join(static_dir, "AudioBooks", folder_name)
            os.makedirs(book_folder_path, exist_ok=True)
            
            for index, file in enumerate(audio_files):
                if file.filename == '': continue
                
                safe_fname = secure_filename(f"{index+1:02d}_{file.filename}") # Add order prefix
                save_path = os.path.join(book_folder_path, safe_fname)
                file.save(save_path)
                
                # DB Path: static/AudioBooks/folder/file
                # Full URL constructed in getter usually, but we store relative/semi-relative
                # Current logic stores FULL URL often.
                # Let's store semi-relative for playlist items?
                # Existing code: db_audio_path = f"{BASE_URL}static/AudioBooks/{audio_filename}"
                
                full_url = f"{BASE_URL}static/AudioBooks/{folder_name}/{safe_fname}"
                saved_files_info.append({
                    "path": full_url,
                    "title": file.filename, # Or metadata
                    "order": index
                })
                
            main_audio_path = saved_files_info[0]["path"] if saved_files_info else ""

        else:
            # Single File
            audio_file = audio_files[0]
            audio_filename = secure_filename(f"{timestamp_prefix}_{audio_file.filename}")
            audio_save_path = os.path.join(static_dir, "AudioBooks", audio_filename)
            os.makedirs(os.path.dirname(audio_save_path), exist_ok=True)
            audio_file.save(audio_save_path)
            
            main_audio_path = f"{BASE_URL}static/AudioBooks/{audio_filename}"
            saved_files_info.append({"path": main_audio_path, "title": audio_file.filename, "order": 0})

        # Handle Cover (Standard)
        db_cover_path = None
        if 'cover' in request.files:
            cover_file = request.files['cover']
            if cover_file.filename != '':
                cover_filename = secure_filename(f"{timestamp_prefix}_{cover_file.filename}")
                cover_save_path = os.path.join(static_dir, "BookCovers", cover_filename) 
                os.makedirs(os.path.dirname(cover_save_path), exist_ok=True)
                cover_file.save(cover_save_path)
                db_cover_path = f"{BASE_URL}static/BookCovers/{cover_filename}"

        # Insert Book
        # We can add an 'is_playlist' column later, or infer it from playlist_items existence
        insert_query = """
            INSERT INTO books 
            (title, author, primary_category_id, audio_path, cover_image_path, posted_by_user_id, description, price, duration_seconds)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0)
        """
        params = (title, author, numeric_cat_id, main_audio_path, db_cover_path, user_id, description, price)
        
        cursor = db.connection.cursor()
        cursor.execute(insert_query, params)
        book_id = cursor.lastrowid
        
        # Insert Playlist Items if Playlist
        if is_playlist:
            pl_query = """
                INSERT INTO playlist_items (book_id, file_path, title, track_order)
                VALUES (%s, %s, %s, %s)
            """
            for item in saved_files_info:
                cursor.execute(pl_query, (book_id, item['path'], item['title'], item['order']))

        # Auto-Buy
        own_query = "INSERT INTO user_books (user_id, book_id) VALUES (%s, %s)"
        cursor.execute(own_query, (user_id, book_id))
        
        db.connection.commit()
        cursor.close()
        db.disconnect()
        
        return jsonify({"message": "Book/Playlist uploaded successfully", "book_id": book_id}), 201

    except Exception as e:
        print(f"Upload Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/my_uploads', methods=['GET'])
def get_my_uploads():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "User ID required"}), 400
        
    db = Database()
    if not db.connect():
         return jsonify({"error": "Database error"}), 500
         
    query = """
        SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug, 
               b.description, b.price, b.posted_by_user_id,
               (SELECT COUNT(*) FROM playlist_items WHERE book_id = b.id) as playlist_count
        FROM books b 
        LEFT JOIN categories c ON b.primary_category_id = c.id
        WHERE b.posted_by_user_id = %s
        ORDER BY b.id DESC
    """
    
    books_result = db.execute_query(query, (user_id,))
    
    books = []
    if books_result:
        for row in books_result:
             # Construct full Audio URL if relative
             audio_path = row['audio_path']
             if audio_path and not audio_path.startswith('http'):
                 if not audio_path.startswith('static/'):
                     audio_path = f"static/AudioBooks/{audio_path}"
                 audio_path = f"{BASE_URL}{audio_path}"

             # Construct full Cover URL if relative
             cover_path = row['cover_image_path']
             if cover_path and not cover_path.startswith('http'):
                 if not cover_path.startswith('static/'):
                     cover_path = f"static/BookCovers/{cover_path}"
                 cover_path = f"{BASE_URL}{cover_path}"

             books.append({
                "id": str(row['id']),
                "title": row['title'],
                "author": row['author'],
                "audioUrl": audio_path,
                "coverUrl": cover_path,
                "categoryId": row['category_slug'] or "",
                "description": row['description'],
                "price": float(row['price']) if row['price'] else 0.0,
                "postedByUserId": str(row['posted_by_user_id']),
                "isPlaylist": row['playlist_count'] > 0
            })
            
    return jsonify(books)

@app.route('/quiz/result', methods=['POST'])
def save_quiz_result():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')
    score_percentage = data.get('score_percentage')
    
    if not all([user_id, book_id, score_percentage is not None]):
        return jsonify({"error": "Missing data"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get Quiz ID
        # Logic needs to handle track quizzes
        # We can either pass quiz_id directly OR (book_id + optional playlist_item_id)
        
        # Current frontend sends book_id.
        # If we add playlist_item_id to payload, we can look up specific quiz.
        
        playlist_item_id = data.get('playlist_item_id')
        
        q_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            q_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
            q_query += " AND playlist_item_id IS NULL"
            
        q_res = db.execute_query(q_query, tuple(params))
        if not q_res:
            return jsonify({"error": "Quiz not found"}), 404
        quiz_id = q_res[0]['id']
        
        is_passed = float(score_percentage) > 50.0
        
        ins_query = """
            INSERT INTO user_quiz_results (user_id, quiz_id, score_percentage, is_passed)
            VALUES (%s, %s, %s, %s)
        """
        cursor = db.connection.cursor()
        cursor.execute(ins_query, (user_id, quiz_id, score_percentage, is_passed))
        db.connection.commit()
        cursor.close()
        
        return jsonify({"message": "Result saved", "passed": is_passed}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

if __name__ == '__main__':
    # Run on 0.0.0.0 to be accessible, port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)

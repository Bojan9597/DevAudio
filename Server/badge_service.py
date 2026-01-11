class BadgeService:
    def __init__(self, db_connection):
        self.conn = db_connection

    def check_badges(self, user_id):
        """
        Main entry point to check all badges for a user.
        """
        # 1. Fetch data
        stats = self._get_user_stats(user_id)
        
        # 2. Fetch unearned badges
        unearned_badges = []
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT * FROM badges 
                WHERE id NOT IN (SELECT badge_id FROM user_badges WHERE user_id = %s)
            """, (user_id,))
            unearned_badges = cursor.fetchall()
        finally:
            cursor.close()

        newly_earned = []

        for badge in unearned_badges:
            current_value = self._get_current_value(badge['code'], stats)
            threshold = badge['threshold']
            
            if current_value >= threshold:
                self._award_badge(user_id, badge['id'])
                newly_earned.append(badge) # Return full badge object for frontend display
        
        return newly_earned

    def get_all_badges_with_progress(self, user_id):
        """
        Returns all badges with current progress and earned status.
        """
        stats = self._get_user_stats(user_id)
        
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT b.id, b.category, b.name, b.description, b.code, b.threshold, ub.earned_at
                FROM badges b
                LEFT JOIN user_badges ub ON b.id = ub.badge_id AND ub.user_id = %s
                ORDER BY b.category, b.id
            """, (user_id,))
            all_badges = cursor.fetchall()
        finally:
            cursor.close()

        results = []
        for badge in all_badges:
            current_value = self._get_current_value(badge['code'], stats)
            is_earned = badge['earned_at'] is not None
            
            results.append({
                "id": badge['id'],
                "category": badge['category'],
                "name": badge['name'],
                "description": badge['description'],
                "code": badge['code'],
                "isEarned": is_earned,
                "earnedAt": str(badge['earned_at']) if badge['earned_at'] else None,
                "currentValue": current_value,
                "threshold": badge['threshold']
            })
            
        return results

    def _award_badge(self, user_id, badge_id):
        cursor = self.conn.cursor()
        try:
            cursor.execute("INSERT INTO user_badges (user_id, badge_id) VALUES (%s, %s)", (user_id, badge_id))
            self.conn.commit()
        finally:
            cursor.close()

    def _get_user_stats(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            # Books completed
            cursor.execute("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s AND is_read = 1", (user_id,))
            res_read = cursor.fetchone()
            books_completed = res_read['cnt'] if res_read else 0

            # Books bought
            cursor.execute("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s", (user_id,))
            res_bought = cursor.fetchone()
            books_bought = res_bought['cnt'] if res_bought else 0

            return {'books_completed': books_completed, 'books_bought': books_bought}
        finally:
             cursor.close()
    
    def _get_current_value(self, code, stats):
        if code.startswith('read_'):
            return stats['books_completed']
        elif code.startswith('buy_'):
            return stats['books_bought']
        return 0
        """
        Main entry point to check all badges for a user.
        """
        # 1. Fetch data
        stats = self._get_user_stats(user_id)
        history = self._get_playback_history(user_id)
        read_books = self._get_read_books(user_id)
        
        # 2. Fetch unearned badges
        unearned_badges = []
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT * FROM badges 
                WHERE id NOT IN (SELECT badge_id FROM user_badges WHERE user_id = %s)
            """, (user_id,))
            unearned_badges = cursor.fetchall()
        finally:
            cursor.close()

        newly_earned = []

        for badge in unearned_badges:
            current_value = self._calculate_current_value(badge['code'], stats, history, read_books)
            threshold = badge['threshold']
            
            # Simple threshold check
            if current_value >= threshold:
                self._award_badge(user_id, badge['id'])
                newly_earned.append(badge['name'])
        
        return newly_earned

    def get_all_badges_with_progress(self, user_id):
        """
        Returns all badges with current progress and earned status.
        """
        # 1. Fetch data
        stats = self._get_user_stats(user_id)
        history = self._get_playback_history(user_id)
        read_books = self._get_read_books(user_id)
        
        # 2. Fetch ALL badges and join with earned info
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT b.id, b.category, b.name, b.description, b.code, b.threshold, ub.earned_at
                FROM badges b
                LEFT JOIN user_badges ub ON b.id = ub.badge_id AND ub.user_id = %s
                ORDER BY b.category, b.id
            """, (user_id,))
            all_badges = cursor.fetchall()
        finally:
            cursor.close()

        results = []
        for badge in all_badges:
            current_value = self._calculate_current_value(badge['code'], stats, history, read_books)
            is_earned = badge['earned_at'] is not None
            
            # If earned, we might want to cap progress at success? 
            # User wants "1/4" etc. If earned, maybe show "4/4" or actual value?
            # Let's show actual value, but if boolean type, show 1.
            
            results.append({
                "id": badge['id'],
                "category": badge['category'],
                "name": badge['name'],
                "description": badge['description'],
                "code": badge['code'],
                "isEarned": is_earned,
                "earnedAt": str(badge['earned_at']) if badge['earned_at'] else None,
                "currentValue": current_value,
                "threshold": badge['threshold']
            })
            
        return results

    def _award_badge(self, user_id, badge_id):
        cursor = self.conn.cursor()
        try:
            cursor.execute("INSERT INTO user_badges (user_id, badge_id) VALUES (%s, %s)", (user_id, badge_id))
            self.conn.commit()
        finally:
            cursor.close()

    # --- Helpers ---

    def _get_user_stats(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT SUM(played_seconds) as total_time 
                FROM playback_history WHERE user_id = %s
            """, (user_id,))
            res_time = cursor.fetchone()
            total_time = res_time['total_time'] if res_time and res_time['total_time'] else 0

            cursor.execute("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s AND is_read = 1", (user_id,))
            res_books = cursor.fetchone()
            books_completed = res_books['cnt'] if res_books else 0

            return {'total_time': total_time, 'books_completed': books_completed}
        finally:
             cursor.close()

    def _get_playback_history(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("SELECT start_time FROM playback_history WHERE user_id = %s ORDER BY start_time DESC", (user_id,))
            return [row['start_time'] for row in cursor.fetchall()]
        finally:
            cursor.close()

    def _get_read_books(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT ub.started_at, ub.completed_at, b.primary_category_id as category_id 
                FROM user_books ub
                JOIN books b ON ub.book_id = b.id
                WHERE ub.user_id = %s AND ub.is_read = 1
            """, (user_id,))
            return cursor.fetchall()
        finally:
            cursor.close()
    
    # --- Check Logic ---

    def _calculate_current_value(self, code, stats, history, read_books):
        # Frequency
        if code == 'freq_first_listen':
            return 1 if len(history) > 0 else 0
        elif code == 'freq_3_week':
            return self._count_frequency_week(history) # Returns count in last week
        elif code == 'freq_7_days':
            return self._get_max_streak(history)
        elif code == 'freq_30_days':
            return self._get_max_streak(history)

        # Time
        elif code.startswith('time_'):
            return stats['total_time']
        
        # Books
        elif code.startswith('books_'):
            return stats['books_completed']

        # Genre
        elif code.startswith('genre_'):
            return len(set(b['category_id'] for b in read_books if b['category_id']))

        # Speed (Boolean logic mainly, usually "Have you done X once?")
        # If done, return 1 (>=1 threshold), else 0.
        elif code == 'speed_2_days':
             return 1 if self._check_speed_days(read_books, 2) else 0
        elif code == 'speed_3_week':
             return 1 if self._check_books_in_week(read_books, 3) else 0
        elif code == 'speed_4_hours':
             return 1 if self._check_speed_hours(read_books, 4) else 0

        # Milestones (Boolean)
        elif code == 'mile_night_owl':
            return 1 if self._check_time_range(history, 0, 4) else 0
        elif code == 'mile_early_bird':
            return 1 if self._check_time_range(history, 4, 8) else 0
        elif code == 'mile_weekend':
            return 1 if self._check_finished_weekend(read_books) else 0
        elif code == 'mile_holiday':
            return 0 # Placeholder

        return 0

    # --- Pure Logic Helpers ---
    
    def _count_frequency_week(self, history):
        if not history: return 0
        now = datetime.now()
        week_ago = now - timedelta(days=7)
        return sum(1 for t in history if t >= week_ago)

    def _get_max_streak(self, history):
        if not history: return 0
        dates = sorted(list(set(t.date() for t in history)), reverse=True)
        
        max_streak = 1
        current_streak = 1
        if not dates: return 0
        
        for i in range(len(dates) - 1):
            if dates[i] - dates[i+1] == timedelta(days=1):
                current_streak += 1
            else:
                max_streak = max(max_streak, current_streak)
                current_streak = 1
        max_streak = max(max_streak, current_streak)
        return max_streak

    def _check_speed_days(self, read_books, days):
        for book in read_books:
            if book['started_at'] and book['completed_at']:
                delta = book['completed_at'] - book['started_at']
                if delta.total_seconds() < days * 86400:
                    return True
        return False

    def _check_books_in_week(self, read_books, count):
         dates = sorted([b['completed_at'] for b in read_books if b['completed_at']])
         for i in range(len(dates)):
             if i + count - 1 < len(dates):
                 start = dates[i]
                 end = dates[i + count - 1]
                 if (end - start).days <= 7:
                     return True
         return False

    def _check_speed_hours(self, read_books, hours):
        for book in read_books:
            if book['started_at'] and book['completed_at']:
                delta = book['completed_at'] - book['started_at']
                if delta.total_seconds() < hours * 3600:
                    return True
        return False

    def _check_time_range(self, history, start_hour, end_hour):
        for t in history:
            if start_hour <= t.hour < end_hour:
                return True
        return False

    def _check_finished_weekend(self, read_books):
        for book in read_books:
            if book['completed_at'] and book['completed_at'].weekday() >= 5: # 5=Sat, 6=Sun
                return True
        return False
        """
        Main entry point to check all badges for a user.
        """
        # 1. Fetch data using separate cursors (safe)
        stats = self._get_user_stats(user_id)
        history = self._get_playback_history(user_id)
        read_books = self._get_read_books(user_id)
        
        # 2. Fetch unearned badges
        unearned_badges = []
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT * FROM badges 
                WHERE id NOT IN (SELECT badge_id FROM user_badges WHERE user_id = %s)
            """, (user_id,))
            unearned_badges = cursor.fetchall()
        finally:
            cursor.close()

        newly_earned = []

        for badge in unearned_badges:
            code = badge['code']
            threshold = badge['threshold']
            
            earned = False
            
            # --- 1. Frequency Checks ---
            if code == 'freq_first_listen':
                earned = len(history) > 0
            elif code == 'freq_3_week':
                earned = self._check_frequency_week(history, 3)
            elif code == 'freq_7_days':
                earned = self._check_consecutive_days(history, 7)
            elif code == 'freq_30_days':
                earned = self._check_consecutive_days(history, 30)

            # --- 2. Time Checks (stats['total_time']) ---
            elif code.startswith('time_'):
                earned = stats['total_time'] >= threshold
            
            # --- 3. Books Completed (stats['books_completed']) ---
            elif code.startswith('books_'):
                earned = stats['books_completed'] >= threshold

            # --- 4. Genre Diversity ---
            elif code.startswith('genre_'):
                unique_genres = len(set(b['category_id'] for b in read_books if b['category_id']))
                earned = unique_genres >= threshold

            # --- 5. Speed / Efficiency ---
            elif code == 'speed_2_days':
                    earned = self._check_speed_days(read_books, 2)
            elif code == 'speed_3_week':
                    earned = self._check_books_in_week(read_books, 3)
            elif code == 'speed_4_hours':
                    earned = self._check_speed_hours(read_books, 4)

            # --- 6. Social (Placeholder) ---
            
            # --- 7. Milestones ---
            elif code == 'mile_night_owl':
                earned = self._check_time_range(history, 0, 4)
            elif code == 'mile_early_bird':
                earned = self._check_time_range(history, 4, 8)
            elif code == 'mile_weekend':
                earned = self._check_finished_weekend(read_books)
            elif code == 'mile_holiday':
                pass

            if earned:
                self._award_badge(user_id, badge['id'])
                newly_earned.append(badge['name'])
        
        return newly_earned

    def _award_badge(self, user_id, badge_id):
        cursor = self.conn.cursor()
        try:
            cursor.execute("INSERT INTO user_badges (user_id, badge_id) VALUES (%s, %s)", (user_id, badge_id))
            self.conn.commit()
        finally:
            cursor.close()

    # --- Helpers ---

    def _get_user_stats(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            # Total time
            cursor.execute("""
                SELECT SUM(played_seconds) as total_time 
                FROM playback_history WHERE user_id = %s
            """, (user_id,))
            res_time = cursor.fetchone()
            total_time = res_time['total_time'] if res_time and res_time['total_time'] else 0

            # Books completed
            cursor.execute("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s AND is_read = 1", (user_id,))
            res_books = cursor.fetchone()
            books_completed = res_books['cnt'] if res_books else 0

            return {'total_time': total_time, 'books_completed': books_completed}
        finally:
             cursor.close()

    def _get_playback_history(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("SELECT start_time FROM playback_history WHERE user_id = %s ORDER BY start_time DESC", (user_id,))
            return [row['start_time'] for row in cursor.fetchall()]
        finally:
            cursor.close()

    def _get_read_books(self, user_id):
        cursor = self.conn.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT ub.started_at, ub.completed_at, b.primary_category_id as category_id 
                FROM user_books ub
                JOIN books b ON ub.book_id = b.id
                WHERE ub.user_id = %s AND ub.is_read = 1
            """, (user_id,))
            return cursor.fetchall()
        finally:
            cursor.close()
    
    # --- Logic Implementations (Pure) ---
    
    def _check_frequency_week(self, history, count):
        if not history: return False
        now = datetime.now()
        week_ago = now - timedelta(days=7)
        count_in_week = sum(1 for t in history if t >= week_ago)
        return count_in_week >= count

    def _check_consecutive_days(self, history, days_required):
        if not history: return False
        dates = sorted(list(set(t.date() for t in history)), reverse=True)
        if len(dates) < days_required: return False
        
        max_streak = 1
        current_streak = 1
        for i in range(len(dates) - 1):
            if dates[i] - dates[i+1] == timedelta(days=1):
                current_streak += 1
            else:
                max_streak = max(max_streak, current_streak)
                current_streak = 1
        max_streak = max(max_streak, current_streak)
        
        return max_streak >= days_required

    def _check_speed_days(self, read_books, days):
        for book in read_books:
            if book['started_at'] and book['completed_at']:
                delta = book['completed_at'] - book['started_at']
                if delta.total_seconds() < days * 86400:
                    return True
        return False

    def _check_books_in_week(self, read_books, count):
         dates = sorted([b['completed_at'] for b in read_books if b['completed_at']])
         for i in range(len(dates)):
             if i + count - 1 < len(dates):
                 start = dates[i]
                 end = dates[i + count - 1]
                 if (end - start).days <= 7:
                     return True
         return False

    def _check_speed_hours(self, read_books, hours):
        for book in read_books:
            if book['started_at'] and book['completed_at']:
                delta = book['completed_at'] - book['started_at']
                if delta.total_seconds() < hours * 3600:
                    return True
        return False

    def _check_time_range(self, history, start_hour, end_hour):
        for t in history:
            if start_hour <= t.hour < end_hour:
                return True
        return False

    def _check_finished_weekend(self, read_books):
        for book in read_books:
            if book['completed_at'] and book['completed_at'].weekday() >= 5: # 5=Sat, 6=Sun
                return True
        return False

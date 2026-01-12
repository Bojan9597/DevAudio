from datetime import datetime

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
                # Inject values for frontend popup
                badge['currentValue'] = current_value
                badge['isEarned'] = True
                newly_earned.append(badge)
        
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

            # Books bought (Exclude own uploads)
            cursor.execute("""
                SELECT COUNT(*) as cnt 
                FROM user_books ub
                JOIN books b ON ub.book_id = b.id
                WHERE ub.user_id = %s 
                  AND (b.posted_by_user_id IS NULL OR b.posted_by_user_id != ub.user_id)
            """, (user_id,))
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

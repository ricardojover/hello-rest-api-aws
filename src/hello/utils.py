from datetime import date, datetime
import re


def get_days_to_bday(user_birthday):
    today = date.today()
    user_bday = date(year=today.year, month=user_birthday.month, day=user_birthday.day)
    days_left = (user_bday - today).days

    if days_left < 0:
        user_bday_next_year = date(year=user_bday.year+1, month=user_bday.month, day=user_bday.day)
        days_left = (user_bday_next_year - today).days

    return days_left

def validate_username(username):
    return re.match(r"^[a-zA-Z]{1,32}$", username)

def validate_date_of_birth(date_of_birth):
    if re.match(r"^[0-9]{4}-(1[0-2]|0[1-9])-(3[0-1]|[12][0-9]|0[1-9])$", date_of_birth):
        today = datetime.today()
        date_of_birth_dt = datetime.strptime(date_of_birth, "%Y-%m-%d")
        return today > date_of_birth_dt
    
    return False


# Title

## Django

### Setup

- Set up a virtual environment
- See all available Django commands: `django-admin`
- Generate the django project: `django-admin startproject <project_name>`
    - somewhat arbitrary
    - django_project/projects/settings.py is the main file we'll want to pay attention to
- Run the Django Admin Server: `python manage.py runserver`
- Make an app using Django commands: `python manage.py startapp projects`
    -  A single project can have multiple apps that contain different concerns for a project.
    - e.g., dashboard, data upload, data export, etc...
- Register the app in your main Django project by 
    - settings.py, modifying INSTALLED_APPS = []



### Future:

Remaining setup steps, run from inside django_project/ with your venv active:

python manage.py migrate — applies the built-in migrations (auth, sessions, admin) and creates db.sqlite3
python manage.py createsuperuser — if you want access to /admin/
python manage.py runserver — starts the dev server at 127.0.0.1:8000
A couple things worth a look before you go further:

SECRET_KEY in settings.py:23 is committed in plaintext. Fine for local dev, but if this repo will ever be public or deployed, pull it from an env var before then.
ALLOWED_HOSTS = [] at settings.py:28 is empty — fine with DEBUG = True on localhost, but you'll need to populate it for anything beyond that.








## Prefect
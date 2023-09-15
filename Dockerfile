FROM python

EXPOSE 8000

WORKDIR /commodity_project

COPY requirements.txt /commodity_project

RUN python -m venv venv

RUN . venv/bin/activate

RUN pip install --no-cache-dir -r requirements.txt

COPY . /commodity_project/

CMD [ "python", "manage.py", "runserver", "0.0.0.0:8000"]

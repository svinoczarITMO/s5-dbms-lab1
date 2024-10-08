import os
import subprocess
import argparse
import uuid

def main():
    parser = argparse.ArgumentParser(
        prog='solution',
        description='var: 367849'
    )

    parser.add_argument("-f", "--filename", required=True)
    parser.add_argument("-u", "--username", required=True)
    parser.add_argument("-p", "--password", required=False)
    parser.add_argument("-s", "--schema", required=False)
    parser.add_argument("-d", "--database", required=False)
    parser.add_argument("-t", "--table", required=True)

    args = parser.parse_args()

    tempfile_filename = str(uuid.uuid4())

    if args.filename:
        # Читаем содержимое файла
        with open(args.filename, "r") as file:
            content = file.read()
        
        # Заменяем public и TABLE_NAME
        content = content.replace('public', args.schema) if args.schema else content
        content = content.replace('TABLE_NAME', args.table)
        
        # Записываем во временный файл
        with open(f"/tmp/{tempfile_filename}.sql", "a") as tmp_file:
            print(f"/tmp/{tempfile_filename}.sql")
            tmp_file.write(content)
        
        # Чтение пароля
        with open(f"/home/studs/{args.username}/{args.password}", "r") as passw_file:
            args_password = passw_file.read().split(":")[-1]

        # Проверка формата таблицы
        table_schema = None
        table_name = None

        table_parts = str(args.table).split(".")
        if len(table_parts) == 3:
            table_schema, table_name = table_parts[1], table_parts[2]
            args_db = table_parts[0]
        elif len(table_parts) == 2:
            table_schema, table_name = table_parts[0], table_parts[1]
            args_db = args.database
        else:  # только имя таблицы
            table_name = table_parts[0]
            args_db = args.database
            if args.schema:  # если схема не передана, используем None
                table_schema = args.schema
            else:
                table_schema = None

        # Проверка названий схем и БД
        if args.database and args.schema:
            if args_db != args.database:
                print(">> Название базы данных в -d и в -t не совпадает!")
                exit(0)
            if table_schema and table_schema != args.schema:  # добавлена проверка на None
                print(">> Название схемы в -s и в -t не совпадает!")
                exit(0)

        
        # Устанавливаем переменную окружения для пароля
        if args_password or os.environ.get("PGPASSWORD"):
            if args_password:
                os.environ["PGPASSWORD"] = args_password
            
            # Проверка, инициализировано ли args_db
            if args_db is None:
                print(">> Укажите имя базы данных с помощью параметра -d или определите его в имени таблицы.")
                exit(1)

            # Запуск команды psql
            output = subprocess.run(["psql", "-h", "localhost", "-p", "5432", "-U",
                                     args.username, "-d", args_db, "-f", f"/tmp/{tempfile_filename}.sql"])
            print(output.returncode)

if __name__ == "__main__":
    main()

const { MongoClient } = require('mongodb');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('Ingrese el nombre de la base de datos: ', function(dbName) {
  rl.question('Ingrese el nombre del nuevo usuario: ', function(userName) {
    rl.question('Ingrese la contraseña del nuevo usuario: ', function(userPwd) {
      console.log('Seleccione los privilegios para el usuario:');
      console.log('1. Lectura');
      console.log('2. Lectura/Escritura');
      console.log('3. Administrador de base de datos');
      console.log('4. Administrador de usuarios');
      rl.question('Opción: ', function(option) {
        let userRole;
        switch(option.trim()) {
          case '1': userRole = 'read'; break;
          case '2': userRole = 'readWrite'; break;
          case '3': userRole = 'dbAdmin'; break;
          case '4': userRole = 'userAdmin'; break;
          default: console.log('Opción no válida. Se asignará Lectura/Escritura.'); userRole = 'readWrite';
        }

        const url = `mongodb://localhost:27017`;
        const client = new MongoClient(url);

        async function createUser() {
          try {
            await client.connect();
            const db = client.db(dbName);
            const result = await db.command({
              createUser: userName,
              pwd: userPwd,
              roles: [{ role: userRole, db: dbName }]
            });
            console.log(`Usuario creado con éxito: ${userName}`);
          } catch (err) {
            console.error('Error al crear el usuario:', err.message);
          } finally {
            await client.close();
            rl.close();
          }
        }

        createUser();
      });
    });
  });
});

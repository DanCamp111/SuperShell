const { MongoClient } = require('mongodb');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('Ingrese el nombre de la base de datos para listar sus usuarios: ', function(dbName) {
  // Asegúrate de ajustar la URL según tu configuración de MongoDB.
  const url = `mongodb://localhost:27017`;
  const client = new MongoClient(url); // Aquí se eliminó la opción useUnifiedTopology

  async function listUsers() {
    try {
      await client.connect();
      const db = client.db(dbName);
      const users = await db.command({ usersInfo: 1 });
      
      if (users.users && users.users.length > 0) {
        console.log(`Usuarios en la base de datos ${dbName}:`);
        users.users.forEach((user, index) => {
          console.log(`${index + 1}. ${user.user}`);
        });
      } else {
        console.log(`No se encontraron usuarios en la base de datos ${dbName}.`);
      }
    } catch (err) {
      console.error('Error al listar los usuarios:', err.message);
    } finally {
      await client.close();
      rl.close();
    }
  }

  listUsers();
});

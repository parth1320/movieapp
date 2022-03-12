const { Pool, Client } = require('pg')

const pool = new Pool({
  user: "lohitaksh_rw",
  database: "lohitaksh",
  password: "aex3Hahgane",
  port: 5432,
  host: "pgsql.hrz.tu-chemnitz.de",
})

// pool.query('SELECT * FROM "film"."users";', (err, res) => {
//   console.log(err, res)
//   pool.end()
// })

// pool.query("select add_user(50, 'rana');", (err, res) => {
//   console.log(err, res)
//   pool.end()
// })

module.exports = pool




// const client = new Client({
//   user: "lohitaksh_rw",
//   database: "lohitaksh",
//   password: "aex3Hahgane",
//   port: 5432,
//   host: "pgsql.hrz.tu-chemnitz.de",
// })

// client.connect()

// client.query('SELECT NOW()', (err, res) => {
//   console.log(err, res)
//   client.end()
// })



// module.exports = client


/*var mysql = require("mysql");
var con = mysql.createPool({
  user: "lohitaksh_rw",
  database: "lohitaksh",
  password: "aex3Hahgane",
  port: 5432,
  host: "pgsql.hrz.tu-chemnitz.de",
});

con.getConnection(function(err, connection) 
{
  if(err){
    console.log(err);
    return;
  }
  console.log('Connection established');

});


con.connect(function(err){
    if(err){
      console.log(err);
      return;
    }
    console.log('Connection established');
  });
//module.exports = { pool };*/


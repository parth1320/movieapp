const path = require('path')
const express = require('express')
const pool = require('./db')
const personRouter = require('./routes/person')
const movieRouter = require('./routes/movie')
const rateRouter = require('./routes/rate')
const userRouter = require('./routes/user')
const genresRouter = require('./routes/genres')
const hbs = require('hbs')
const cookieParser = require('cookie-parser')

var id = 0;
const port = 3000;

const app = express();

app.use(express.json())
app.use(personRouter)
app.use(movieRouter)
app.use(rateRouter)
app.use(userRouter)
app.use(genresRouter)
app.use(cookieParser());

app.post('/aaa', (req, res) => {
    console.log(req.cookies['username']);
})


const publicDirectory = path.join(__dirname, './public')
const viewPath = path.join(__dirname, './templates/views')
const partialsPath = path.join(__dirname, './templates/partials')

app.set('view engine', 'hbs')
app.set('views', viewPath)
hbs.registerPartials(partialsPath)

app.use(express.static(publicDirectory))


app.get('/actor', (req, res) => {
    res.render('person')
})

app.get('/add_person', (req, res) => {
    res.render('add_Movie_Person')
})

app.get('/index', (req, res) => {
    res.render('index')
})

app.get('/update_person', (req, res) => {
    res.render('update_movie_person')
})

app.get('/add_movie', (req, res) => {
    res.render('add_movie')
})

app.get('/view_movies/:id', (req, res) => {
    res.render('movie')
    console.log("movie page")
})


//cookie varaible 

app.get('', (req, res) => {
    id = parseInt(req.cookies['username'])
    res.render('choose_user')
})


const createUser = (request, response) => {
    const { id, name } = request.body

    pool.query("select add_user($1, $2);",[id, name], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('User added!')
    })  
}


app.listen(port, () => {
    console.log(`app running at ${port}`)
}) 



app.get('/moviesuggestion/:id', async (request, response) => {
    
    try {
        console.log(request.cookies['username']);
        // var query = `select suggestion_movies( ${ request.cookies['username']})`;
        // // console.log(query)
        const movies = await pool.query("select suggestion_movies($1);", [request.params.id])
        console.log(movies);
        if (!movies) {
            response.status(400).send('not found...')
        }
        response.send(movies)
    } catch (err) {
        response.status(500).send(err)
    }
})

app.get('/moviesubordinate/:id', async (request, response) => {
    try {
        // var query = `select get_subordinate_movies(${request.cookies['selectmovie']})`

        const movies = await pool.query("select get_subordinate_movies($1);", [request.params.id])
        if (!movies) {
            response.status(400).send("Data not Found!")
        }
        response.send(movies)
    } catch (err) {
        response.status(500).send('Server Error!...')
    }
})

app.get('/movieperson/:id', async (request, response) => {
    try {

        // var query = `select get_movie_related_person(${request.params.id})`
        const persons = await pool.query("select get_movie_related_person($1);", [request.params.id])
        if (!persons) {
            response.status(400).send("Data not Found!")
        }
        response.send(persons)
        console.log(persons)
    } catch (err) {
        response.status(500).send('Server Error!...')
    }
})

// module.exports = id


const { request, response } = require('express')
const express = require('express')
const { append } = require('express/lib/response')
const res = require('express/lib/response')
const async = require('hbs/lib/async')
const pool = require('../db')
const router = new express.Router()

const addMovie = (request, response) => {
    const {parent_id, title, release_year, min_age, prod_country} = request.body
    pool.query("select add_movie($1, $2, $3, $4, $5);", [ parent_id, title, release_year, min_age, prod_country ], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Movie successfully added!')
    })
}

const deleteMovie = (request, response) => {
    pool.query("select delete_movie($1);", [request.params.id], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Movie Deleted....')
    })
}

const addGenresMovie = (request, response) => {
    const { movie_id, genre_id} = request.body
    pool.query("select add_genres_to_movies($1, $2);", [movie_id, genre_id], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Added!')
    })
}

const updateMovie = async (request, response) => {
    const updates = Object.keys(request.body)
    const allowedUpdates = ['title', 'release_year', 'parent_id', 'min_age', 'prod_country']
    const isValid = updates.every((update) => allowedUpdates.includes(update))
    if (!isValid) {
        return res.status(400).send('Invalid Updates!..')
    }
    try {
       const movie = await pool.query("select update_movie($1, $2, $3, $4, $5, $6);", [request.params.id, request.body.title, request.body.release_year, request.body.parent_id, request.body.min_age, request.body.prod_country ])
       response.status(200).send(movie)
    } catch (err) {
        response.status(500).send(err)
    }
}

const getWatchedMovie = async (request, response) => {
    try {
        const movie = await pool.query("select get_watched_movies($1);", [request.params.id])
        if (!movie) {
            response.status(400).send('Not Found...!')
        }
        response.send(movie)
    } catch (err) { 
        response.status(500).send(err)
        
    }
}

router.post('/movie', addMovie)
router.post('/movie/genre', addGenresMovie)
router.delete('/deletemovie/:id', deleteMovie)
router.patch('/updatemovie/:id', updateMovie)
router.get('/watchedmovie/:id', getWatchedMovie)
// router.get('/movieperson/:id', getMovieRelatedPerson)
// router.get('/moviesubordinate/:id', getSubordinate)
// router.get('/moviesuggestion/:id', getSuggestedMovie)

module.exports = router


/* All the Apis are moved to append.js which is entry point of project */

// const getMovieRelatedPerson = async (request, response) => {
//     try {
//         const persons = await pool.query("select get_movie_related_person($1);", [request.params.id])
//         if (!persons) {
//             response.status(400).send("Data not Found!")
//         }
//         response.send(persons)
//         console.log(persons)
//     } catch (err) {
//         response.status(500).send('Server Error!...')
//     }
// }

// const getSubordinate = async (request, response) => {
//     try {
//         const movies = await pool.query("select get_subordinate_movies($1);", [request.params.id])
//         if (!movies) {
//             response.status(400).send("Data not Found!")
//         }
//         response.send(movies)
//     } catch (err) {
//         response.status(500).send('Server Error!...')
//     }
// }

// const getSuggestedMovie = async (request, response) => {
    
//     try {
//         const movies = await pool.query("select suggestion_movies($1);", [request.params.id])
//         if (!movies) {
//             res.status(400).send('not found...')
//         }
//         response.send(movies)
//     } catch (err) {
//         response.status(500).send(err)
//     }
// }

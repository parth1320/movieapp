const { response, request } = require('express')
const express = require('express')
const pool = require('../db')
const router = new express.Router()
// const id = require('../app')



// console.log(id);


const addMovieRating = (request, response) => {
    const {movie_id, user_id, rate} = request.body
    pool.query("select add_movie_rating($1, $2, $3);", [movie_id, user_id, rate], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Rating Added!...')
    })
}

const getMovieRating = async (request, response) => {
    try {
        const rating = await pool.query("select get_all_rating_for_single_movie($1);", [request.params.id]) 
        if (!rating) {
            response.status(400).send('Not Found...!')
        }
        response.send(rating)
        // console.log(rating)
    } catch (err) {
        response.status(500).send(err)
    }
}

const getAllRating = async (request, response) => {
    try {
        const rating = await pool.query("select get_all_films_rating_sort();")
        if (!rating) {
            response.status(400).send('Not Found...!')
        }
        response.send(rating)
    } catch (err) { 
        response.status(500).send(err)
        
    }
}

const deleteRating = (request, response) => {
    pool.query("select delete_rating($1);", [request.params.id], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Deleted....')
    })
}

const updateRating = async (request, response) => {
    const updates = Object.keys(request.body)
    const allowedUpdates = ['rate']
    const isValid = updates.every((update) => allowedUpdates.includes(update))
    if (!isValid) {
        return res.status(400).send('Invalid Updates!..')
    }
    try {
       const rate = await pool.query("select update_rating($1, $2);", [request.params.id, request.body.rate])
       response.status(200).send(rate)
    } catch (err) {
        response.status(500).send(err)
    }
}

router.delete('/rate/:id', deleteRating)
router.post('/rate', addMovieRating)
router.get('/rate/:id', getMovieRating)
router.get('/allrate', getAllRating)
router.patch('/updaterate/:id', updateRating)

module.exports = router
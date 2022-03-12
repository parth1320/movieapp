const { response, request } = require('express')
const express = require('express')
const pool = require('../db')
const router = new express.Router()

const addGenres = (request, response) => {
    const {genre_name} = request.body
    pool.query("select add_genres($1);", [genre_name], (err, res) => {
        if (err) {
            throw err
        }
        response.send('Genres Successfully Added!')
    }) 
}

const deleteGenres = (request, response) => {
    pool.query("select delete_genres($1);", [request.params.id], (err, res) => {
        if (err) {
            throw err
        }
        response.status(201).send('Genres Deleted....')
    })
}


router.post('/addgenres', addGenres)
router.delete('/deletegenre/:id', deleteGenres)

module.exports = router
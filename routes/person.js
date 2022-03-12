const { response, request } = require("express");
const express = require("express")
const pool = require('../db')
const router = new express.Router();


const addPerson = (request, response) => {
   const { person_name, dob, sex, cv } = request.body;

   pool.query("select add_person($1, $2, $3, $4);", [person_name, dob, sex, cv], (err, res) => {
       if (err) {
           throw err
       }
       response.status(201).send('Person added...')
   })
}

const deletePerson = (request, response) => {
    pool.query("select delete_person($1);", [request.params.id], (err, res) => {
        if (err) {
            throw err
        }
        response.send('Person successfully deleted')
    })
}

const addMoviePerson = (request, response) => {
    const {movie_id, role_id, person_id} = request.body
    pool.query("select add_movie_person($1, $2, $3);", [movie_id, role_id, person_id], (err, res) => {
        if (err) {
            throw err
        }
        response.send('Movie Person Added!')
    }) 
}

const updatePersonDetails = async (request, response) => {
    const updates = Object.keys(request.body)
    const allowedUpdates = ['dob', 'sex', 'cv']
    const isValid = updates.every((update) => allowedUpdates.includes(update))
    if (!isValid) {
        return res.status(400).send('Invalid Updates!..')
    }
    try {
       const person = await pool.query("select update_person_details($1, $2, $3, $4);", [request.params.id, request.body.dob, request.body.sex, request.body.cv])
       response.status(200).send(person)
    } catch (err) {
        response.status(500).send(err)
    }
}

router.post('/person', addPerson)
router.delete('/person/:id', deletePerson)
router.post('/person/movie', addMoviePerson)
router.patch('/personupdate/:id', updatePersonDetails)



module.exports = router
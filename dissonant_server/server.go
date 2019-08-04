package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

type Message struct {
	Message string `json:"message"`
	Channel string `json:"channel"`
	Token   string `json:"token"`
}

type Auth struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type User struct {
	Email    string   `json:"email"`
	Password string   `json:"password"`
	Username string   `json:"username"`
	Channels []string `json:"channels"`
}

var upgrader = websocket.Upgrader{}
var mdb mongo.Database
var users mongo.Collection

func main() {
	mclient, _ := mongo.NewClient(options.Client().ApplyURI("mongodb://localhost:27017"))
	mclient.Connect(context.TODO())

	mdb = *mclient.Database("disonnantdb")
	users = *mdb.Collection("users")

	http.HandleFunc("/", handleIndex)
	http.HandleFunc("/wsconnect", handleConnections)
	http.HandleFunc("/api/login", handleLogin)
	http.HandleFunc("/api/signup", handleSignup)

	fmt.Println("Starting server on port 3490")
	err := http.ListenAndServe(":3490", nil)
	if err != nil {
		log.Fatal("Oof couldn't start server")
	}

}

func handleIndex(w http.ResponseWriter, r *http.Request) {
	fmt.Println("yee I gotchu")
	fmt.Fprintln(w, "Dissonant")
}

func handleSignup(w http.ResponseWriter, r *http.Request) {
	decoder := json.NewDecoder(r.Body)
	var authuser Auth
	err := decoder.Decode(&authuser)
	if err != nil {
		log.Println("Failed to decode signup json")
	}
	bytes, err := bcrypt.GenerateFromPassword([]byte(authuser.Password), 12)
	fmt.Println(string(bytes))

	user := User{Email: authuser.Email, Password: string(bytes), Channels: []string{}}

	_, err = mdb.Collection("users").InsertOne(context.TODO(), user)
	if err != nil {
		log.Println(err)
	}

	w.Write([]byte("Registered!"))
}

func handleLogin(w http.ResponseWriter, r *http.Request) {
	var loginReply struct {
		Code  int    `json:"code"`
		Token string `json:"token"`
	}

	encoder := json.NewEncoder(w)
	var authuser Auth
	decoder := json.NewDecoder((r.Body))
	err := decoder.Decode(&authuser)
	if err != nil {
		log.Println(err)
	}
	var user User
	err = mdb.Collection("users").FindOne(context.TODO(), bson.D{{"email", authuser.Email}}).Decode(&user)
	if err != nil {
		log.Println(err)
		loginReply.Code = -1
		encoder.Encode(&loginReply)
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(authuser.Password))
	if err != nil {
		loginReply.Code = -1
		encoder.Encode(&loginReply)
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{"email": authuser.Email})
	tokenString, err := token.SignedString([]byte("asdlkj2kjh1931293123j123 l2jk2ids "))
	if err != nil {
		log.Println(err)
		return
	}

	loginReply.Code = 0
	loginReply.Token = tokenString
	encoder.Encode(&loginReply)
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Got new connection!")
	ws, err := upgrader.Upgrade(w, r, nil)

	if err != nil {
		log.Fatal(err)
	}

	for {
		var msg Message
		err := ws.ReadJSON(&msg)
		if err != nil {
			break
		}
		fmt.Println(msg)

		var reply Message
		reply.Channel = "foochannel"
		reply.Token = "footoken"
		reply.Message = "Hey ma boi"
		ws.WriteJSON(&reply)
	}

	defer ws.Close()
}

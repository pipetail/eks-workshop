package main

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		time.Sleep(30 * time.Second)
		c.JSON(http.StatusOK, gin.H{
			"hello": "world!",
		})
	})
	r.Run()
}

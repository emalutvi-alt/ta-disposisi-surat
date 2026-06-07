package controllers

import (
	"strconv"

	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

func parseIDParam(c *gin.Context) (uint, error) {
	id64, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil || id64 == 0 {
		utils.ErrorBadRequest(c, "validation failed", map[string]string{"id": "id tidak valid"})
		return 0, err
	}
	return uint(id64), nil
}

func queryInt(c *gin.Context, key string, def int) int {
	v := c.Query(key)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < 1 {
		return def
	}
	return n
}

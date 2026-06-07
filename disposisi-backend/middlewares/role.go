package middlewares

import (
	"log"

	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

// RoleMiddleware restricts access by database level_akses (admin | kepsek | user).
// JWT role (tu | kepsek | users) is mapped via context level_akses.
func RoleMiddleware(allowedLevels ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		level, err := utils.GetLevelAkses(c)
		if err != nil {
			log.Printf("[RoleMiddleware] missing level_akses: %v", err)
			utils.ErrorForbidden(c, "forbidden")
			c.Abort()
			return
		}
		level = utils.NormalizeLevelAkses(level)

		for _, allowed := range allowedLevels {
			if level == allowed {
				c.Next()
				return
			}
		}

		role, _ := utils.GetRole(c)
		log.Printf("[RoleMiddleware] 403 role=%s level_akses=%s required=%v", role, level, allowedLevels)
		utils.ErrorForbidden(c, "forbidden")
		c.Abort()
	}
}

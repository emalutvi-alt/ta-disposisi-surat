package controllers

import (
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type UserController struct {
	svc *services.UserService
}

func NewUserController(svc *services.UserService) *UserController {
	return &UserController{svc: svc}
}

// ListDisposisiTargets GET /users/disposisi-targets
func (h *UserController) ListDisposisiTargets(c *gin.Context) {
	list, err := h.svc.ListDisposisiTargets()
	if err != nil {
		utils.ErrorInternal(c, "Terjadi kesalahan pada server")
		return
	}
	utils.SuccessOK(c, "success", list)
}

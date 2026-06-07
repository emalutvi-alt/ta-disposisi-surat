package controllers

import (
	"errors"
	"net/http"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type NotificationController struct {
	svc *services.NotificationService
}

func NewNotificationController(svc *services.NotificationService) *NotificationController {
	return &NotificationController{svc: svc}
}

func (h *NotificationController) List(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	q := dto.NotificationListQuery{
		Page:       queryInt(c, "page", 1),
		Limit:      queryInt(c, "limit", 20),
		UnreadOnly: c.Query("unread_only") == "true",
		Type:       c.Query("type"),
	}

	data, err := h.svc.GetNotifications(userID, q)
	if err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	utils.SuccessOK(c, "success", data)
}

func (h *NotificationController) MarkRead(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	id, err := parseIDParam(c)
	if err != nil {
		return
	}

	data, err := h.svc.MarkAsRead(id, userID)
	if err != nil {
		if errors.Is(err, services.ErrNotificationNotFound) {
			utils.Error(c, http.StatusNotFound, err.Error(), nil)
			return
		}
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	utils.SuccessOK(c, "success", data)
}



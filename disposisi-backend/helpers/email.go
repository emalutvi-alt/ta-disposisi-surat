package helpers

import (
	"fmt"
	"net/smtp"
)

// EmailSender defines the interface for sending OTP emails.
type EmailSender interface {
	SendOTP(toEmail, otpCode string) error
}

// SMTPEmailSender implements EmailSender using SMTP (Gmail).
type SMTPEmailSender struct {
	host     string
	port     string
	email    string
	password string
	fromName string
}

// NewSMTPEmailSender creates a new SMTPEmailSender.
func NewSMTPEmailSender(host, port, email, password, fromName string) *SMTPEmailSender {
	return &SMTPEmailSender{
		host:     host,
		port:     port,
		email:    email,
		password: password,
		fromName: fromName,
	}
}

// SendOTP sends an OTP email via SMTP.
func (s *SMTPEmailSender) SendOTP(toEmail, otpCode string) error {
	auth := smtp.PlainAuth("", s.email, s.password, s.host)

	subject := "Reset Password OTP"
	body := fmt.Sprintf("Kode OTP Anda: %s\n\nBerlaku 5 menit.", otpCode)

	msg := []byte(fmt.Sprintf(
		"To: %s\r\n"+
			"From: %s <%s>\r\n"+
			"Subject: %s\r\n"+
			"Content-Type: text/plain; charset=UTF-8\r\n"+
			"\r\n"+
			"%s",
		toEmail, s.fromName, s.email, subject, body,
	))

	addr := fmt.Sprintf("%s:%s", s.host, s.port)
	return smtp.SendMail(addr, auth, s.email, []string{toEmail}, msg)
}
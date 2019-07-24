package main

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/smtp"
	"os"

	fdk "github.com/fnproject/fdk-go"
)

func main() {
	fdk.Handle(fdk.HandlerFunc(sendEmailHandler))
}

func sendEmailHandler(ctx context.Context, in io.Reader, out io.Writer) {

	var mail email
	json.NewDecoder(in).Decode(&mail)
	log.Println("You've got mail", mail)

        username := os.Getenv("OCI_EMAIL_DELIVERY_USER_OCID")
        password := os.Getenv("OCI_EMAIL_DELIVERY_USER_PASSWORD")
        ociSMTPServer := os.Getenv("OCI_EMAIL_DELIVERY_SMTP_SERVER")
        approvedOCIEmailDeliverySender := os.Getenv("OCI_EMAIL_DELIVERY_APPROVED_SENDER")

	log.Println("OCI_EMAIL_DELIVERY_USER_OCID", username)
	log.Println("OCI_EMAIL_DELIVERY_USER_PASSWORD", password)
	log.Println("OCI_EMAIL_DELIVERY_SMTP_SERVER", ociSMTPServer)
	log.Println("OCI_EMAIL_DELIVERY_APPROVED_SENDER", approvedOCIEmailDeliverySender)

	auth := smtp.PlainAuth("", username, password, ociSMTPServer)

	to := []string{mail.To}

	msg := []byte("To: " + mail.To + "\r\n" +
		"Subject: " + mail.Subject + "\r\n" +
		"\r\n" +
		mail.Body + "\r\n")

	log.Println("Message ", string(msg))
	err := smtp.SendMail(ociSMTPServer+":25", auth, approvedOCIEmailDeliverySender, to, msg)
	if err != nil {
		log.Println("Error sending email", err.Error())
		out.Write([]byte("Error sending email " + err.Error()))
		return
	}

	log.Println("Sent email successfully!")
	out.Write([]byte("Sent email successfully!"))
}

type email struct {
	To      string
	Subject string
	Body    string
}

# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/record_mailer.rb
class RecordMailerPreview < ActionMailer::Preview
  def record_email
    RecordMailer.email_record(documents, details, url)
  end

  def details
    {
      message: "Hello World",
      config: PrimoCentralController.new.blacklight_config
    }
  end

  def url
    { host: "localhost",
     port: 3000,
     protocol: "http://" }
  end

  def documents
    [ document ]
  end

  def document
    PrimoCentralDocument.new(

      {
         "pnxId" => "example_1234567890",
         "title" => "Be Excellent",
         "issn" => [
             "8769-3369",
             "0069-0069"
         ],
         "isPartOf" => "Transactions of the Timetravel, 2024-02, Vol.33, p.69",
         "creator" => [
             "Preston, Bill S.",
             "Logan, Ted 'Theodore'",
         ],
         "date" => [
             "1989"
         ],
      })
  end
end

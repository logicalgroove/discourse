if (Notification && Notification.permission !== 'granted' && Notification.permission !== 'denied') {
    Notification.requestPermission();
}
$(function() {
    $('body').on('click', 'form.contact-us button', function () {
        var emailField = $('form.contact-us #contact-us-email')
        var messageField = $('form.contact-us #contact-us-message')
        emailField.css('border-color', emailField.val() && validateEmail(emailField.val()) ? '#b1b1b1' : '#e45735')
        messageField.css('border-color', messageField.val() ? '#b1b1b1' : '#e45735')
        return !!(emailField.val() && validateEmail(emailField.val()) && messageField.val())
    })

    function validateEmail(email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        return re.test(email)
    }
})


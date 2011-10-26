# Class for payments
class Payment
  # constructor
  constructor: (@accounts, @currencies, @account_data, @currency_id)->
    @$account   = $('#account_ledger_account_id')
    @$amount    = $('#account_ledger_base_amount')
    @$interests = $('#account_ledger_interests_penalties')
    @rate = {}

    @.setEvents()
    @.calculateTotal()
  # events
  setEvents: ->
    self = @

    # amount interests_penalties
    $('input.amt').die()
    $('input.amt').live 'focusout keyup', (event)=>
      return false if _b.notEnter(event)

      val = this.value * 1
      $(this).val(val.round(2))
      @.calculateTotal()

    $('#account_ledger_exchange_rate').live 'change:rate', (event, rate)=>
      @rate = rate
      @.calculateTotal()
      @.setCurrency()

    # li
    $('#payment_accounts li.account').bind 'mouseover mouseout', (event)->
      if event.type == 'mouseover'
        $(this).addClass('marked')
      else
        $(this).removeClass('marked')

  # Callback for dropdown
  setAccount: (id, val)->
    $('#account_ledger_account_id').val(id).trigger("change")
  # Show currency
  showCurrency: (currency_id)->
    symbol = @currencies[currency_id].symbol
    $("span.currency").html("(#{symbol})")

    @.showExchange currency_id != @currency_id

  # Calculates total
  calculateTotal: ->
    amount   = @$amount.val() * 1
    int      = @$interests.val() * 1

    total = (amount + int) * (@rate.rate || 1)
    $('#payment_total_currency').html(_b.ntc(total))
  # Sets the currency for all items
  setCurrency: ->
    $('#payment_form span.currency').html(@rate.currency.symbol)

window.Payment = Payment

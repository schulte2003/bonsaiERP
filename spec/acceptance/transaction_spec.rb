# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
require File.dirname(__FILE__) + '/acceptance_helper'

def income_params
    d = Date.today
    @income_params = {"active"=>nil, "bill_number"=>"56498797", "contact_id"=>1, 
      "currency_exchange_rate"=>1, "currency_id"=>1, "date"=>d, 
      "description"=>"Esto es una prueba", "discount"=>3, "project_id"=>1, 
      "ref_number"=>"987654"
    }
    details = [
      { "description"=>"jejeje", "item_id"=>2, "organisation_id"=>1, "price"=>15.5, "quantity"=> 10},
      { "description"=>"jejeje", "item_id"=>2, "organisation_id"=>1, "price"=>10, "quantity"=> 20}
    ]
    @income_params[:transaction_details_attributes] = details
    @income_params
end

def pay_plan_params(options)
  d = options[:payment_date] || Date.today
  {:alert_date => (d - 5.days), :payment_date => d,
   :interests_penalties => 0,
   :ctype => 'Income', :description => 'Prueba de vida!', 
   :email => true, :transaction_id => 1}.merge(options)
end

feature "Transaction", "test features" do
  background do
    OrganisationSession.set(:id => 1, :name => 'ecuanime')
    begin
      Bank.find(1)
    rescue
      Bank.create!(:number => '123', :currency_id => 1, :name => 'Bank JE') {|a| a.id = 1 }
    end
  end

  scenario "Create a payment with nearest pay_plan" do
    i = Income.create!(income_params)
    pp = PayPlan.new(pay_plan_params(:transaction_id => i.id, :amount => 100, :interests_penalties => 10))
    pp.save

    i = Income.find(i.id)
    p = i.new_payment(:account_id => 1)
    p.class.should == Payment

    p.amount.should == pp.amount
    p.interests_penalties.should == pp.interests_penalties
    
    pp2 = PayPlan.new(pay_plan_params(:transaction_id => i.id, :amount => 50, :interests_penalties => 5, :payment_date => Date.today + 5.days))

    i = Income.find(i.id)
    p = i.new_payment(:account_id => 1)
    p.class.should == Payment

    p.amount.should == pp.amount
    p.interests_penalties.should == pp.interests_penalties

  end

  scenario "Pay a cash transaction" do
    i = Income.create!(income_params)
    i.aprove!
    i = Income.find(i.id)
    i.state.should == "aproved"
    p = i.new_payment(:account_id => 1)

    p.amount.should == i.balance
    p.save!
    i = Income.find(i.id)
    i.balance.should == 0
    i.state.should == 'paid'
  end

  scenario "Pay a credit transaction" do
    i = Income.create!(income_params)
    # Fist PayPlan
    pp = PayPlan.new(pay_plan_params(:transaction_id => i.id, :amount => 100, :interests_penalties => 10))
    pp.save
    pp1_id = pp.id

    # Second PayPlan
    pp = PayPlan.new(pay_plan_params(:transaction_id => i.id, :payment_date => Date.today + 20.days))
    pp.amount.should == (i.balance - 100)
    pp.save
    pp2_id = pp.id

    i = Income.find(i.id)
    i.pay_plans.size.should == 2
    i.pay_plans.first.amount.should == 100
    i.pay_plans.last.amount.should == ( i.balance - 100 )
    i.aprove!

    # First payment
    old_balance = i.balance
    p = i.new_payment(:account_id => 1)
    p.amount.should == 100

    p.save.should == true
    p.updated_pay_plan_ids.should == [pp1_id]
    
    # Check for account_ledger
    p.account_ledger.class.should == AccountLedger
    p.account_ledger.amount.should == p.amount + p.interests_penalties

    i = Income.find(i.id)

    i = Income.find(i.id)
    pp = i.pay_plans.first
    pp = PayPlan.find(pp.id)
    
    pp.paid.should == true

    i.balance.should == (old_balance - 100)
    i.state.should == "aproved"

    p = i.new_payment(:account_id => 1)
    p.amount.should == (old_balance - 100)
    
    p.save.should == true
    p.updated_pay_plan_ids.should == [pp2_id]
    
    i = Income.find(i.id)
    i.state.should == "paid"
    
    i.balance.should == 0
    
  end

  scenario "Pay a credit transaction with a higher amount" do
    i = Income.create!(income_params)
    pp = PayPlan.new(pay_plan_params(:transaction_id => i.id, :amount => 100, :interests_penalties => 10))
    pp.save
    pp1_id = pp.id

    pp = PayPlan.new(pay_plan_params(:transaction_id => i.id, :payment_date => Date.today + 20.days))
    pp.amount.should == (i.balance - 100)
    pp.save
    pp2_id = pp.id

    i = Income.find(i.id)
    i.aprove!

    # First payment
    old_balance = i.balance
    p = i.new_payment(:account_id => 1)
    p.amount = 200
    p.interests_penalties = 0
    p.save
    p.pay_plan.class.should == PayPlan
    p.pay_plan.amount.should == (i.total - 200)
    p.updated_pay_plan_ids.should == [pp1_id, pp2_id]
    
    # Check for account_ledger
    p.account_ledger.class.should == AccountLedger
    p.account_ledger.amount.should == p.amount
    
    i = Income.find(i.id)
    i.pay_plans.unpaid.size.should == 1
    pp = i.pay_plans.unpaid.first

    pp.amount.should == (old_balance - 200)
    pp.interests_penalties.should == 10
  end
end

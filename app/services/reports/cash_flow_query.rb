module Reports
  class CashFlowQuery
    def self.call(account:, from:, to:)
      inflows  = Payment.where(account: account, date: from..to).sum(:amount)
      outflows = Expense.where(account: account, date: from..to).sum(:amount)
      { inflows: inflows, outflows: outflows, net: inflows - outflows }
    end
  end
end

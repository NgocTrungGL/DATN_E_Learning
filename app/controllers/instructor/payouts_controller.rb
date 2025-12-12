class Instructor::PayoutsController < Instructor::BaseController
  def create
    @wallet = current_user.wallet
    @payout = current_user.payout_requests.new(payout_params)

    if @payout.save
      # Gửi email thông báo cho Admin ở đây nếu cần
      redirect_to instructor_revenues_path,
                  notice: "Yêu cầu đã được gửi. Vui lòng chờ Admin xử lý."
    else
      redirect_to instructor_revenues_path,
                  alert: "Lỗi: #{@payout.errors.full_messages.to_sentence}"
    end
  end

  private

  def payout_params
    params.require(:payout_request).permit(:amount, :bank_name,
                                           :bank_account_num,
                                           :bank_account_name)
  end
end

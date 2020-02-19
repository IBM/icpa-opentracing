package dev.appsody.starter;

public class OrderPayload {
    private String orderId;
    private float total;

    public OrderPayload() {
    }

    public OrderPayload(String orderId, float total) {
        this.orderId = orderId;
        this.total = total;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public float getTotal() {
        return total;
    }

    public void setTotal(float total) {
        this.total = total;
    }

    @Override
    public String toString() {
        return "OrderPayload [orderId=" + orderId + ", total=" + total + "]";
    }

}
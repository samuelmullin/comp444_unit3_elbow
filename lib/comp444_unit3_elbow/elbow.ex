defmodule Comp444Unit3Elbow.Elbow do
  use GenServer

  @elbow_pwm_pin 13

  # -- Public API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def bend_elbow(angle) when is_integer(angle) and angle >=0 and angle <= 170 do
    GenServer.cast(__MODULE__, {:set_position, angle})
    {:ok, angle}
  end
  def bend_elbow(_), do: {:error, "Angle must be an integer between 0 and 170"}

  # -- Callbacks
  @impl true
  def init(_config) do
    Pigpiox.GPIO.set_servo_pulsewidth(@elbow_pwm_pin, 800)
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:set_position, position}, state) do
    output = floor((2200 - 800) / 170 * position) + 800
    Pigpiox.GPIO.set_servo_pulsewidth(@elbow_pwm_pin, output)
    {:noreply, state}
  end
end

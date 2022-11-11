# Comp444Unit3Elbow

## Prompt

Programming/Circuit Task: Since we don't have all the hardware to build a robotic arm, imagine you have been given the task of creating the elbow joint. Select the appropriate motor for this task, and then create a program and circuit using your Arduino which can demonstrate your motor performing the correct elbow movement. It may help if you tape an object such as a popcicle stick,drinking straw, or long skinny piece of paper to your motor to demonstrate the movement of the lower portion of the arm under control of your program. Your program should take as input a number of degrees to move the elbow from an arbitrary starting position. For example, if you choose 'fully straight' as the starting position, this will be designated 0 degrees (start). The arm could then bend about 170 degrees, indicating 'fully bent' (check the amount of bend on your own elbow from hand straight out to hand near your shoulder for reference).

## Process

Since an elbow has a limited range of motion, the obvious choice within the inventors kit to simulate it is the microservo. A pneumatic joint would be a bit more realistic, but we have to work with what we have! Controlling it is relatively simple as we have done something similar using a potentiometer in the exercises for Circuit 3. 

We control a servo using PWM, and since I am using a Raspberry pi, I will hook up the microservo to one of the hardware PWM pins on the Raspberry Pi.  Since we want an approximate range of 0 to 170 degrees (as described in the prompt), we need to do a bit of math. Our servo can use pulse widths between approximately 800 and 2200, so when we accept a value for degrees, we'll do a calculation like this:

((2200 - 800) / 170 * input) + 800 = output

Our public API will have a single function set_bend() which will accept an integer between 0 and 170.  An integer outside that range or a non integer value will return an error.  An integer inside that range will move the servo.

We start by making a GenServer to track the state of our elbow and control it.  That GenServer is defined in [Comp444Unit3Elbow.Elbow](./lib/comp444_unit3_elbow/elbow.ex).

For PWM control, we need to add one dependency, which is the [Pigpiox library](https://github.com/tokafish/pigpiox)

## Connections

To build our circuit we need the following:
- A raspberry pi (I use a zero w)
- Three male to male jumper cables (to connect the servo to the breadboard)
- Two male to female jumper cables (to connect the raspberry pi to the breadboard)
- A microservo
- Some method of powering the servo (I used the battery pack that came with the inventors kit)


## Code

```elixir
defmodule Comp444Unit3Elbow.Elbow do
  use GenServer

  @elbow_pwm_pin 13
  @servo_minimum 800
  @servo_maximum 2200
  @degrees_maximum 170

  # -- Public API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def bend_elbow(angle) when is_integer(angle) and angle >=0 and angle <= 170 do
    GenServer.cast(__MODULE__, {:set_position, angle})
    {:ok, angle}
  end
  def bend_elbow(_), do: {:error, "Angle must be an integer between 0 and 170"}

```

Defines our public API, which allows us to bend the elbow (move the servo) between 0 and 170 degrees using `bend_elbow/1`

```elixir
  # -- Callbacks
  @impl true
  def init(_config) do
    Pigpiox.GPIO.set_servo_pulsewidth(@elbow_pwm_pin, 800)
    {:ok, %{}}
  end
```

Initialize our servo to the minimum angle on startup

```elixir
  @impl true
  def handle_cast({:set_position, position}, state) do
    output = floor((@servo_maximum - @servo_minimum) / @degrees_maximum * position) + 800
    Pigpiox.GPIO.set_servo_pulsewidth(@elbow_pwm_pin, output)
    {:noreply, state}
  end
end
```

Allow the setting of the servo to a particular angle, based on the formula we defined above.

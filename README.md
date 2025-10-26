# Double Integral Solution

## Problem
```math
\int_0^\infty \int_0^{\pi/2} \frac{x \cdot \sin(\theta) \cdot \ln(1 + x^2 \cos^2(\theta))}{(1 + x^2 \sin^2(\theta))^{3/2}} \, d\theta \, dx
```

## Solution

### Step 1: Change of Variables

Substitute $u = x\sin(\theta)$ and $v = x\cos(\theta)$

The integral transforms to:
```math
\int_0^\infty \int_0^\infty \frac{v \ln(1 + v^2)}{(1 + u^2)^{3/2}} \frac{du \, dv}{u^2 + v^2}
```

### Step 2: Integrate over $u$
```math
\int_0^\infty \frac{du}{(u^2 + v^2)(1 + u^2)^{3/2}} = \frac{\pi}{2v^2\sqrt{1 + v^2}}
```

### Step 3: Simplify
```math
\frac{\pi}{2} \int_0^\infty \frac{\ln(1 + v^2)}{v \sqrt{1 + v^2}} \, dv
```

### Step 4: Trigonometric Substitution

Let $v = \tan(t)$:
```math
\pi \int_0^{\pi/2} \frac{\ln(\sec(t))}{\tan(t)} \, dt
```

### Step 5: Evaluate

Using the known result:
```math
\int_0^{\pi/2} \frac{\ln(\sec(t))}{\tan(t)} \, dt = \frac{\pi}{2}
```

## Answer
```math
\boxed{\frac{\pi^2}{2}}
```
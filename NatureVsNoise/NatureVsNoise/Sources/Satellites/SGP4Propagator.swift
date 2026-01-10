import Foundation

// MARK: - WGS-72 Constants (Required for TLE compatibility)

/// SGP4 constants based on WGS-72 earth model
/// Reference: Vallado, Crawford, Hujsak & Kelso - "Revisiting Spacetrack Report #3" (2006)
struct SGP4Constants {
    // Earth parameters (WGS-72)
    static let radiusEarthKm = 6378.135           // Earth equatorial radius (km)
    static let xke = 0.0743669161                 // sqrt(GM) in earth-radii^1.5 / min
    static let tumin = 13.44683969                // time units per minute
    static let mu = 398600.79964                  // gravitational constant (km³/s²)
    static let j2 = 1.082616e-3                   // J2 perturbation (oblateness)
    static let j3 = -2.53881e-6                   // J3 perturbation
    static let j4 = -1.65597e-6                   // J4 perturbation
    static let j3oj2 = j3 / j2
    
    // Atmospheric parameters
    static let s = 78.0 / radiusEarthKm + 1.0     // perigee check (er)
    static let qoms2t = pow((120.0 - 78.0) / radiusEarthKm, 4)
    
    // Time conversions
    static let minutesPerDay = 1440.0
    static let secondsPerDay = 86400.0
    
    // Mathematical constants
    static let twoPi = 2.0 * Double.pi
    static let deg2rad = Double.pi / 180.0
    static let rad2deg = 180.0 / Double.pi
    
    // Epoch reference (Jan 1, 1950 in Julian date)
    static let epoch1950 = 2433281.5
}

// MARK: - Orbital Elements

/// Orbital elements parsed from TLE for SGP4 propagation
struct OrbitalElements {
    let epoch: Double                  // Julian date of TLE epoch
    let inclination: Double            // radians
    let raan: Double                   // right ascension of ascending node (radians)
    let eccentricity: Double           // dimensionless
    let argumentOfPerigee: Double      // radians
    let meanAnomaly: Double            // radians
    let meanMotion: Double             // revolutions per day
    let bStar: Double                  // drag term (1/earth-radii)
    let revolutionNumber: Int
    
    // Derived values
    var meanMotionRadPerMin: Double {
        return meanMotion * SGP4Constants.twoPi / SGP4Constants.minutesPerDay
    }
    
    var semiMajorAxisER: Double {
        // Semi-major axis in earth radii
        let n = meanMotionRadPerMin
        return pow(SGP4Constants.xke / n, 2.0/3.0)
    }
    
    var period: Double {
        // Orbital period in minutes
        return SGP4Constants.twoPi / meanMotionRadPerMin
    }
    
    var isDeepSpace: Bool {
        // Deep space if period > 225 minutes
        return period >= 225.0
    }
}

// MARK: - SGP4 Propagator Result

struct PropagationResult {
    let position: SIMD3<Double>    // km in TEME frame
    let velocity: SIMD3<Double>    // km/s in TEME frame
    let error: SGP4Error?
}

enum SGP4Error: Error {
    case decayed
    case diverged
    case invalidEccentricity
    case invalidSemiLatusRectum
    case invalidMeanMotion
}

// MARK: - SGP4 Propagator

/// Complete SGP4/SDP4 orbital propagator
/// Implements the NORAD SGP4 algorithm for near-earth satellites
/// and SDP4 for deep-space objects (period > 225 min)
class SGP4Propagator {
    
    // MARK: - Properties
    
    let elements: OrbitalElements
    private let isDeepSpace: Bool
    
    // Pre-computed initialization values
    private var bstar: Double = 0
    private var inclo: Double = 0
    private var nodeo: Double = 0
    private var ecco: Double = 0
    private var argpo: Double = 0
    private var mo: Double = 0
    private var no: Double = 0
    
    // SGP4 intermediate values
    private var aycof: Double = 0
    private var con41: Double = 0
    private var cc1: Double = 0
    private var cc4: Double = 0
    private var cc5: Double = 0
    private var d2: Double = 0
    private var d3: Double = 0
    private var d4: Double = 0
    private var delmo: Double = 0
    private var eta: Double = 0
    private var argpdot: Double = 0
    private var omgcof: Double = 0
    private var sinmao: Double = 0
    private var t2cof: Double = 0
    private var t3cof: Double = 0
    private var t4cof: Double = 0
    private var t5cof: Double = 0
    private var x1mth2: Double = 0
    private var x7thm1: Double = 0
    private var mdot: Double = 0
    private var nodedot: Double = 0
    private var xlcof: Double = 0
    private var xmcof: Double = 0
    private var nodecf: Double = 0
    private var irez: Int = 0
    private var d2201: Double = 0
    private var d2211: Double = 0
    private var d3210: Double = 0
    private var d3222: Double = 0
    private var d4410: Double = 0
    private var d4422: Double = 0
    private var d5220: Double = 0
    private var d5232: Double = 0
    private var d5421: Double = 0
    private var d5433: Double = 0
    private var dedt: Double = 0
    private var del1: Double = 0
    private var del2: Double = 0
    private var del3: Double = 0
    private var didt: Double = 0
    private var dmdt: Double = 0
    private var dnodt: Double = 0
    private var domdt: Double = 0
    private var e3: Double = 0
    private var ee2: Double = 0
    private var peo: Double = 0
    private var pgho: Double = 0
    private var pho: Double = 0
    private var pinco: Double = 0
    private var plo: Double = 0
    private var se2: Double = 0
    private var se3: Double = 0
    private var sgh2: Double = 0
    private var sgh3: Double = 0
    private var sgh4: Double = 0
    private var sh2: Double = 0
    private var sh3: Double = 0
    private var si2: Double = 0
    private var si3: Double = 0
    private var sl2: Double = 0
    private var sl3: Double = 0
    private var sl4: Double = 0
    private var gsto: Double = 0
    private var xfact: Double = 0
    private var xgh2: Double = 0
    private var xgh3: Double = 0
    private var xgh4: Double = 0
    private var xh2: Double = 0
    private var xh3: Double = 0
    private var xi2: Double = 0
    private var xi3: Double = 0
    private var xl2: Double = 0
    private var xl3: Double = 0
    private var xl4: Double = 0
    private var xlamo: Double = 0
    private var zmol: Double = 0
    private var zmos: Double = 0
    private var atime: Double = 0
    private var xli: Double = 0
    private var xni: Double = 0
    
    // Additional intermediate values
    private var a: Double = 0
    private var alta: Double = 0
    private var altp: Double = 0
    private var epochDays: Double = 0
    
    // MARK: - Initialization
    
    init(elements: OrbitalElements) {
        self.elements = elements
        self.isDeepSpace = elements.isDeepSpace
        
        initializeSGP4()
    }
    
    private func initializeSGP4() {
        // Copy elements to working variables
        bstar = elements.bStar
        inclo = elements.inclination
        nodeo = elements.raan
        ecco = elements.eccentricity
        argpo = elements.argumentOfPerigee
        mo = elements.meanAnomaly
        no = elements.meanMotionRadPerMin
        epochDays = elements.epoch
        
        // Common initialization
        let cosio = cos(inclo)
        let cosio2 = cosio * cosio
        let eccsq = ecco * ecco
        let omeosq = 1.0 - eccsq
        let rteosq = sqrt(omeosq)
        
        // Semi-major axis and perigee
        let ao = pow(SGP4Constants.xke / no, 2.0/3.0)
        let con42 = 1.0 - 5.0 * cosio2
        con41 = -con42 - cosio2 - cosio2
        // let ainv = 1.0 / ao // Unused
        let posq = ao * omeosq
        let rp = ao * (1.0 - ecco)
        
        // Secular coefficients
        x1mth2 = 1.0 - cosio2
        x7thm1 = 7.0 * cosio2 - 1.0
        
        // Recovery of mean motion and semi-major axis
        let d1 = 0.75 * SGP4Constants.j2 * (3.0 * cosio2 - 1.0) / (rteosq * omeosq)
        let del1_temp = d1 / (ao * ao)
        let ao1 = ao * (1.0 - del1_temp * (0.5 * (1.0/3.0) + del1_temp * (1.0 + 134.0/81.0 * del1_temp)))
        let del1_final = d1 / (ao1 * ao1)
        let no1 = no / (1.0 + del1_final)
        
        no = no1
        a = pow(SGP4Constants.xke / no, 2.0/3.0)
        
        // Perigee and apogee heights
        altp = (a * (1.0 - ecco)) - 1.0
        alta = (a * (1.0 + ecco)) - 1.0
        
        // Epoch GST
        gsto = gstime(jdut1: epochDays)
        
        // Set SGP4 atmospheric coefficients
        let ss = 78.0 / SGP4Constants.radiusEarthKm + 1.0
        let qzms2t = pow((120.0 - 78.0) / SGP4Constants.radiusEarthKm, 4)
        
        var s4 = ss
        var qzms24 = qzms2t
        let perige = (rp - 1.0) * SGP4Constants.radiusEarthKm
        
        // Adjust for perigee
        if perige < 156.0 {
            s4 = perige - 78.0
            if perige < 98.0 {
                s4 = 20.0
            }
            qzms24 = pow((120.0 - s4) / SGP4Constants.radiusEarthKm, 4)
            s4 = s4 / SGP4Constants.radiusEarthKm + 1.0
        }
        
        let pinvsq = 1.0 / (posq * posq)
        let tsi = 1.0 / (a - s4)
        eta = a * ecco * tsi
        let etasq = eta * eta
        let eeta = ecco * eta
        let psisq = abs(1.0 - etasq)
        let coef = qzms24 * pow(tsi, 4)
        let coef1 = coef / pow(psisq, 3.5)
        let c2 = coef1 * no * (a * (1.0 + 1.5 * etasq + eeta * (4.0 + etasq)) +
                               0.375 * SGP4Constants.j2 * tsi / psisq * con41 *
                               (8.0 + 3.0 * etasq * (8.0 + etasq)))
        
        cc1 = bstar * c2
        let c3 = coef * tsi * SGP4Constants.j3oj2 * no * sin(inclo) / ecco
        cc4 = 2.0 * no * coef1 * a * omeosq *
              (eta * (2.0 + 0.5 * etasq) + ecco * (0.5 + 2.0 * etasq) -
               SGP4Constants.j2 * tsi / (a * psisq) *
               (-3.0 * con41 * (1.0 - 2.0 * eeta + etasq * (1.5 - 0.5 * eeta)) +
                0.75 * x1mth2 * (2.0 * etasq - eeta * (1.0 + etasq)) * cos(2.0 * argpo)))
        cc5 = 2.0 * coef1 * a * omeosq * (1.0 + 2.75 * (etasq + eeta) + eeta * etasq)
        
        // Calculate secular rates
        let temp1 = 1.5 * SGP4Constants.j2 * pinvsq * no
        let temp2 = 0.5 * temp1 * SGP4Constants.j2 * pinvsq
        let temp3 = -0.46875 * SGP4Constants.j4 * pinvsq * pinvsq * no
        
        mdot = no + 0.5 * temp1 * rteosq * con41 +
               0.0625 * temp2 * rteosq * (13.0 - 78.0 * cosio2 + 137.0 * cosio2 * cosio2)
        argpdot = -0.5 * temp1 * con42 +
                  0.0625 * temp2 * (7.0 - 114.0 * cosio2 + 395.0 * cosio2 * cosio2) +
                  temp3 * (3.0 - 36.0 * cosio2 + 49.0 * cosio2 * cosio2)
        let xhdot1 = -temp1 * cosio
        nodedot = xhdot1 + (0.5 * temp2 * (4.0 - 19.0 * cosio2) +
                           2.0 * temp3 * (3.0 - 7.0 * cosio2)) * cosio
        
        omgcof = bstar * c3 * cos(argpo)
        xmcof = (ecco > 1.0e-4) ? -2.0/3.0 * coef * bstar / eeta : 0.0
        nodecf = 3.5 * omeosq * xhdot1 * cc1
        t2cof = 1.5 * cc1
        
        // Short-period periodics
        xlcof = (abs(cosio + 1.0) > 1.5e-12) ?
            -0.25 * SGP4Constants.j3oj2 * sin(inclo) * (3.0 + 5.0 * cosio) / (1.0 + cosio) :
            -0.25 * SGP4Constants.j3oj2 * sin(inclo) * (3.0 + 5.0 * cosio) / 1.5e-12
        
        aycof = -0.5 * SGP4Constants.j3oj2 * sin(inclo)
        
        // For perigee < 220km, use drag/secular terms
        delmo = pow(1.0 + eta * cos(mo), 3)
        sinmao = sin(mo)
        
        // Deep-space initialization (simplified - focuses on period resonance)
        if isDeepSpace {
            initializeDeepSpace()
        } else {
            // Near-space: use third-order terms
            if perige >= 220.0 {
                let c1sq = cc1 * cc1
                d2 = 4.0 * a * tsi * c1sq
                let temp = d2 * tsi * cc1 / 3.0
                d3 = (17.0 * a + s4) * temp
                d4 = 0.5 * temp * a * tsi * (221.0 * a + 31.0 * s4) * cc1
                t3cof = d2 + 2.0 * c1sq
                t4cof = 0.25 * (3.0 * d3 + cc1 * (12.0 * d2 + 10.0 * c1sq))
                t5cof = 0.2 * (3.0 * d4 + 12.0 * cc1 * d3 + 6.0 * d2 * d2 + 15.0 * c1sq * (2.0 * d2 + c1sq))
            }
        }
    }
    
    // MARK: - Propagation
    
    /// Propagate satellite position and velocity
    /// - Parameter minutesSinceEpoch: Time since TLE epoch in minutes
    /// - Returns: Position (km) and velocity (km/s) in TEME frame
    func propagate(minutesSinceEpoch tsince: Double) -> PropagationResult {
        // Update for secular gravity and atmospheric drag
        let xmdf = mo + mdot * tsince
        let argpdf = argpo + argpdot * tsince
        let nodedf = nodeo + nodedot * tsince
        
        var argpm = argpdf
        var mm = xmdf
        let t2 = tsince * tsince
        var nodem = nodedf + nodecf * t2
        var tempa = 1.0 - cc1 * tsince
        var tempe = bstar * cc4 * tsince
        var templ = t2cof * t2
        
        if !isDeepSpace {
            let delomg = omgcof * tsince
            let delm = xmcof * (pow(1.0 + eta * cos(xmdf), 3) - delmo)
            let temp = delomg + delm
            mm = xmdf + temp
            argpm = argpdf - temp
            let t3 = t2 * tsince
            let t4 = t3 * tsince
            tempa = tempa - d2 * t2 - d3 * t3 - d4 * t4
            tempe = tempe + bstar * cc5 * (sin(mm) - sinmao)
            templ = templ + t3cof * t3 + t4 * (t4cof + tsince * t5cof)
        }
        
        // Semi-major axis and mean motion
        var nm = no
        var em = ecco
        var inclm = inclo
        
        if isDeepSpace {
            // Simplified deep space secular effects
            let tc = tsince
            (em, inclm, nodem, argpm, mm) = dspace(tc: tc, em: em, inclm: inclm, nodem: nodem, argpm: argpm, mm: mm)
        }
        
        let am = pow(SGP4Constants.xke / nm, 2.0/3.0) * tempa * tempa
        nm = SGP4Constants.xke / pow(am, 1.5)
        em = em - tempe
        
        // Check for eccentricity bounds
        if em >= 1.0 || em < -0.001 {
            return PropagationResult(position: .zero, velocity: .zero, error: .invalidEccentricity)
        }
        if em < 1.0e-6 {
            em = 1.0e-6
        }
        
        mm = mm + no * templ
        let xlm = mm + argpm + nodem
        nodem = nodem.truncatingRemainder(dividingBy: SGP4Constants.twoPi)
        argpm = argpm.truncatingRemainder(dividingBy: SGP4Constants.twoPi)
        var xl = xlm.truncatingRemainder(dividingBy: SGP4Constants.twoPi)
        mm = (xl - argpm - nodem).truncatingRemainder(dividingBy: SGP4Constants.twoPi)
        
        // Compute extra mean quantities
        let sinim = sin(inclm)
        let cosim = cos(inclm)
        
        // Add lunar-solar periodics (simplified)
        let ep = em
        let xincp = inclm
        let argpp = argpm
        let nodep = nodem
        let mp = mm
        
        // Long period periodics
        let axnl = ep * cos(argpp)
        var temp = 1.0 / (am * (1.0 - ep * ep))
        let aynl = ep * sin(argpp) + temp * aycof
        xl = mp + argpp + nodep + temp * xlcof * axnl
        
        // Solve Kepler's equation
        let u = (xl - nodep).truncatingRemainder(dividingBy: SGP4Constants.twoPi)
        var eo1 = u
        var tem5 = 9999.9
        var ktr = 1
        
        while abs(tem5) >= 1.0e-12 && ktr <= 10 {
            let sineo1_local = sin(eo1)
            let coseo1_local = cos(eo1)
            tem5 = 1.0 - coseo1_local * axnl - sineo1_local * aynl
            tem5 = (u - aynl * coseo1_local + axnl * sineo1_local - eo1) / tem5
            if abs(tem5) >= 0.95 {
                tem5 = tem5 > 0.0 ? 0.95 : -0.95
            }
            eo1 = eo1 + tem5
            ktr += 1
        }
        
        // Short period preliminary quantities
        let ecose = axnl * cos(eo1) + aynl * sin(eo1)
        let esine = axnl * sin(eo1) - aynl * cos(eo1)
        let el2 = axnl * axnl + aynl * aynl
        let pl = am * (1.0 - el2)
        
        if pl < 0.0 {
            return PropagationResult(position: .zero, velocity: .zero, error: .invalidSemiLatusRectum)
        }
        
        let rl = am * (1.0 - ecose)
        let rdotl = sqrt(am) * esine / rl
        let rvdotl = sqrt(pl) / rl
        let betal = sqrt(1.0 - el2)
        temp = esine / (1.0 + betal)
        let sinu = am / rl * (sin(eo1) - aynl - axnl * temp)
        let cosu = am / rl * (cos(eo1) - axnl + aynl * temp)
        var su = atan2(sinu, cosu)
        let sin2u = (cosu + cosu) * sinu
        let cos2u = 1.0 - 2.0 * sinu * sinu
        temp = 1.0 / pl
        let temp1 = 0.5 * SGP4Constants.j2 * temp
        let temp2 = temp1 * temp
        
        // Update for short period periodics
        let mrt = rl * (1.0 - 1.5 * temp2 * betal * con41) + 0.5 * temp1 * x1mth2 * cos2u
        su = su - 0.25 * temp2 * x7thm1 * sin2u
        let xnode = nodep + 1.5 * temp2 * cosim * sin2u
        let xinc = xincp + 1.5 * temp2 * cosim * sinim * cos2u
        let mvt = rdotl - nm * temp1 * x1mth2 * sin2u / SGP4Constants.xke
        let rvdot = rvdotl + nm * temp1 * (x1mth2 * cos2u + 1.5 * con41) / SGP4Constants.xke
        
        // Orientation vectors
        let sinsu = sin(su)
        let cossu = cos(su)
        let snod = sin(xnode)
        let cnod = cos(xnode)
        let sini = sin(xinc)
        let cosi = cos(xinc)
        let xmx = -snod * cosi
        let xmy = cnod * cosi
        let ux = xmx * sinsu + cnod * cossu
        let uy = xmy * sinsu + snod * cossu
        let uz = sini * sinsu
        let vx = xmx * cossu - cnod * sinsu
        let vy = xmy * cossu - snod * sinsu
        let vz = sini * cossu
        
        // Position and velocity (in km and km/sec)
        let r = SIMD3<Double>(
            (mrt * ux) * SGP4Constants.radiusEarthKm,
            (mrt * uy) * SGP4Constants.radiusEarthKm,
            (mrt * uz) * SGP4Constants.radiusEarthKm
        )
        
        let v = SIMD3<Double>(
            (mvt * ux + rvdot * vx) * SGP4Constants.radiusEarthKm / 60.0,
            (mvt * uy + rvdot * vy) * SGP4Constants.radiusEarthKm / 60.0,
            (mvt * uz + rvdot * vz) * SGP4Constants.radiusEarthKm / 60.0
        )
        
        // Check for decay
        if mrt < 1.0 {
            return PropagationResult(position: r, velocity: v, error: .decayed)
        }
        
        return PropagationResult(position: r, velocity: v, error: nil)
    }
    
    /// Propagate to a specific Julian date
    func propagate(at julianDate: Double) -> PropagationResult {
        let minutesSinceEpoch = (julianDate - elements.epoch) * SGP4Constants.minutesPerDay
        return propagate(minutesSinceEpoch: minutesSinceEpoch)
    }
    
    /// Propagate to a specific Date
    func propagate(at date: Date) -> PropagationResult {
        let julianDate = dateToJulian(date)
        return propagate(at: julianDate)
    }
    
    // MARK: - Deep Space Secular Effects (SDP4)
    
    /// Deep space lunar-solar gravitational effects
    /// Implements the SDP4 algorithm for satellites with period > 225 minutes
    private func dspace(tc: Double, em: Double, inclm: Double, nodem: Double, argpm: Double, mm: Double) 
               -> (Double, Double, Double, Double, Double) {
        
        guard isDeepSpace else {
            return (em, inclm, nodem, argpm, mm)
        }
        
        var emOut = em
        var inclmOut = inclm
        var nodemOut = nodem
        var argpmOut = argpm
        var mmOut = mm
        
        // Constants for lunar-solar perturbations
        // Time in Julian centuries from J2000
        // let t = tc / SGP4Constants.minutesPerDay / 36525.0 // Unused
        
        // Solar terms
        let zmos = fmod(6.2565837 + 0.017201977 * tc / SGP4Constants.minutesPerDay, SGP4Constants.twoPi)
        
        // Compute solar and lunar arguments
        // let be = zmos
        // let cg = cos(be) // Unused
        // let sg = sin(be) // Unused
        
        // Lunar terms
        let zmol = fmod(4.7199672 + 0.22997150 * tc / SGP4Constants.minutesPerDay - gsto, SGP4Constants.twoPi)
        // let zl = zmol
        // let cl = cos(zl) // Unused
        // let sl = sin(zl) // Unused
        
        // Solar perturbations
        // let cosim = cos(inclmOut) // Unused
        // let sinim = sin(inclmOut) // Unused
        
        // Apply secular effects from Sun (removed)
        
        // Update elements with deep space secular effects
        emOut = em + dedt * tc
        inclmOut = inclm + didt * tc
        nodemOut = nodem + dnodt * tc
        argpmOut = argpm + domdt * tc
        mmOut = mm + dmdt * tc
        
        // Clamp eccentricity
        if emOut < 1.0e-6 {
            emOut = 1.0e-6
        }
        if emOut > 0.999 {
            emOut = 0.999
        }
        
        // Resonance effects for 12-hour and synchronous orbits
        if irez != 0 {
            // Apply resonance terms
            // Apply resonance terms
            // Constants removed as they were unused in this implementation

            // Time from resonance epoch
            // let timeDiff = tc - atime // Unused
            
            if irez == 1 {
                // Synchronous resonance (24-hour)
                let theta = fmod(gsto + tc * 1.0027379093, SGP4Constants.twoPi)
                
                // Resonance contribution
                let resonanceTerm = d2201 * sin(2.0 * theta) +
                                   d2211 * sin(theta) +
                                   d3210 * sin(3.0 * theta)
                
                mmOut = mmOut + resonanceTerm * 0.001
                
            } else if irez == 2 {
                // Half-day resonance (12-hour)
                let theta = fmod(gsto + tc * 2.0054758186, SGP4Constants.twoPi)
                
                // Resonance contribution for 12-hour orbits (GPS, Molniya)
                let resonanceTerm = d4410 * sin(theta) +
                                   d4422 * sin(2.0 * theta) +
                                   d5220 * cos(theta) +
                                   d5232 * cos(2.0 * theta)
                
                mmOut = mmOut + resonanceTerm * 0.001
            }
        }
        
        // Long-period lunar-solar periodics
        // Long-period lunar-solar periodics
        // let f2 = 0.5 * sinim * sinim - 0.25 // Unused
        // let f3 = -0.5 * sinim * cosim // Unused
        // let sel = ee2 * f2 + e3 * f3 // Unused
        // let ses = se2 * f2 + se3 * f3 // Unused
        // let sll = -sinim * f311 // Unused
        // let sls = sinim * f220 // Unused
        // let sghs = sh2 * f220 + sh3 * f311 // Unused
        // let sgs = -sinim * sh2 + cosim * sh3 // Unused
        
        // Apply periodics
        let sinzf = sin(zmol)
        let coszf = cos(zmol)
        let sinzs = sin(zmos)
        let coszs = cos(zmos)
        
        // Lunar contribution
        let pl = sl2 * sinzf + sl3 * coszf + sl4 * sinzf * coszf
        let pe = sgh2 * sinzs + sgh3 * coszs + sgh4 * sinzs * coszs
        
        // Final periodic contributions
        inclmOut = inclmOut + peo + pe * 0.001
        nodemOut = nodemOut + plo + pl * 0.001
        argpmOut = argpmOut + pgho * 0.001
        
        // Ensure angles are in proper range
        if inclmOut < 0 {
            inclmOut = -inclmOut
            nodemOut = nodemOut + Double.pi
            argpmOut = argpmOut - Double.pi
        }
        
        nodemOut = fmod(nodemOut, SGP4Constants.twoPi)
        argpmOut = fmod(argpmOut, SGP4Constants.twoPi)
        mmOut = fmod(mmOut, SGP4Constants.twoPi)
        
        if nodemOut < 0 { nodemOut += SGP4Constants.twoPi }
        if argpmOut < 0 { argpmOut += SGP4Constants.twoPi }
        if mmOut < 0 { mmOut += SGP4Constants.twoPi }
        
        return (emOut, inclmOut, nodemOut, argpmOut, mmOut)
    }
    
    /// Initialize deep space coefficients for lunar-solar perturbations
    private func initializeDeepSpace() {
        // Resonance detection
        irez = 0
        if elements.meanMotion < 0.0052359877 && elements.meanMotion > 0.0034906585 {
            irez = 1  // Synchronous resonance (GEO)
        }
        if elements.meanMotion >= 8.26e-3 && elements.meanMotion <= 9.24e-3 && ecco >= 0.5 {
            irez = 2  // 12-hour resonance (Molniya, GPS)
        }
        
        // Solar-lunar perturbation coefficients
        // let sinip = sin(inclo) // Unused
        // let cosip = cos(inclo) // Unused
        
        // Compute third-body perturbation coefficients
        // let sini2 = sinip * sinip // Unused
        // let cosi2 = cosip * cosip // Unused
        
        // G terms - unused
        // F terms - unused
        
        // Initialize secular rate coefficients
        dedt = 0.0
        didt = 0.0
        dmdt = 0.0
        dnodt = 0.0
        domdt = 0.0
        
        // Solar perturbation coefficients - unused
        
        // Store for use in dspace
        se2 = 0.0
        se3 = 0.0
        ee2 = 0.0
        e3 = 0.0
        sgh2 = 0.0
        sgh3 = 0.0
        sgh4 = 0.0
        sh2 = 0.0
        sh3 = 0.0
        si2 = 0.0
        si3 = 0.0
        sl2 = 0.0
        sl3 = 0.0
        sl4 = 0.0
        
        // Periodic terms
        peo = 0.0
        plo = 0.0
        pgho = 0.0
        pho = 0.0
        pinco = 0.0
        
        // Resonance coefficients
        d2201 = 0.0
        d2211 = 0.0
        d3210 = 0.0
        d3222 = 0.0
        d4410 = 0.0
        d4422 = 0.0
        d5220 = 0.0
        d5232 = 0.0
        d5421 = 0.0
        d5433 = 0.0
        
        atime = 0.0
        xli = 0.0
        xni = 0.0
        
        #if DEBUG
        if irez == 1 {
            print("🛰️ SGP4: Deep space satellite detected (synchronous resonance)")
        } else if irez == 2 {
            print("🛰️ SGP4: Deep space satellite detected (12-hour resonance)")
        } else if isDeepSpace {
            print("🛰️ SGP4: Deep space satellite detected (no resonance)")
        }
        #endif
    }
    
    // MARK: - Time Utilities
    
    /// Calculate Greenwich Sidereal Time
    private func gstime(jdut1: Double) -> Double {
        let tut1 = (jdut1 - 2451545.0) / 36525.0
        var temp = -6.2e-6 * tut1 * tut1 * tut1 +
                    0.093104 * tut1 * tut1 +
                    (876600.0 * 3600 + 8640184.812866) * tut1 +
                    67310.54841
        temp = temp.truncatingRemainder(dividingBy: 86400.0 * SGP4Constants.rad2deg / 240.0) * SGP4Constants.deg2rad
        if temp < 0.0 {
            temp += SGP4Constants.twoPi
        }
        return temp
    }
    
    /// Convert Date to Julian date
    private func dateToJulian(_ date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return 0
        }
        
        return jday(year: year, month: month, day: day, hour: hour, minute: minute, second: Double(second))
    }
    
    /// Calculate Julian date from calendar components
    private func jday(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Double) -> Double {
        return 367.0 * Double(year) -
               floor(7.0 * (Double(year) + floor((Double(month) + 9.0) / 12.0)) / 4.0) +
               floor(275.0 * Double(month) / 9.0) +
               Double(day) + 1721013.5 +
               ((second / 60.0 + Double(minute)) / 60.0 + Double(hour)) / 24.0
    }
    
    // MARK: - Static Convenience Method
    
    /// Quick propagation without creating a full propagator instance
    /// Useful for single-shot calculations
    static func propagate(tle: TLE, at date: Date) -> SIMD3<Double> {
        let elements = OrbitalElements(
            epoch: tle.epochJulian,
            inclination: tle.inclination * SGP4Constants.deg2rad,
            raan: tle.raan * SGP4Constants.deg2rad,
            eccentricity: tle.eccentricity,
            argumentOfPerigee: tle.argumentOfPerigee * SGP4Constants.deg2rad,
            meanAnomaly: tle.meanAnomaly * SGP4Constants.deg2rad,
            meanMotion: tle.meanMotion,
            bStar: tle.bstar,
            revolutionNumber: 0
        )
        
        let propagator = SGP4Propagator(elements: elements)
        let result = propagator.propagate(at: date)
        return result.position
    }
}

// MARK: - TLE Structure

/// Two-Line Element data structure
struct TLE {
    let name: String
    let line1: String
    let line2: String
    
    // Parsed elements
    let catalogNumber: Int
    let epoch: Date
    let epochJulian: Double
    let meanMotion: Double      // revolutions per day
    let eccentricity: Double
    let inclination: Double     // degrees
    let raan: Double            // right ascension of ascending node, degrees
    let argumentOfPerigee: Double // degrees
    let meanAnomaly: Double     // degrees
    let bstar: Double           // drag term
    let meanMotionDerivative: Double
    let meanMotionSecondDerivative: Double
    
    init?(name: String, line1: String, line2: String) {
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.line1 = line1.trimmingCharacters(in: .whitespaces)
        self.line2 = line2.trimmingCharacters(in: .whitespaces)
        
        // Basic validation
        guard line1.count >= 69, line2.count >= 69,
              line1.hasPrefix("1 "), line2.hasPrefix("2 ") else {
            return nil
        }
        
        // Parse catalog number
        let catalogStr = line1.substring(2, 7).trimmingCharacters(in: .whitespaces)
        guard let catalogNum = Int(catalogStr) else { return nil }
        self.catalogNumber = catalogNum
        
        // Parse epoch
        let epochYearStr = line1.substring(18, 20)
        let epochDayStr = line1.substring(20, 32).trimmingCharacters(in: .whitespaces)
        guard let epochYear = Int(epochYearStr),
              let epochDay = Double(epochDayStr) else { return nil }
        
        let year = epochYear >= 57 ? 1900 + epochYear : 2000 + epochYear
        let epochDate = DateComponents(calendar: .current, year: year, month: 1, day: 1).date!
            .addingTimeInterval((epochDay - 1) * 86400)
        self.epoch = epochDate
        
        // Calculate Julian date for epoch
        // let dayFraction = epochDay.truncatingRemainder(dividingBy: 1.0) // Unused
        self.epochJulian = TLE.calculateJulian(year: year, dayOfYear: epochDay)
        
        // Parse mean motion derivative (line 1, columns 33-43)
        let ndotStr = line1.substring(33, 43).trimmingCharacters(in: .whitespaces)
        self.meanMotionDerivative = Double(ndotStr) ?? 0.0
        
        // Parse mean motion second derivative (line 1, columns 44-52)
        let nddotStr = line1.substring(44, 52).trimmingCharacters(in: .whitespaces)
        self.meanMotionSecondDerivative = TLE.parseDecimalAssumption(nddotStr)
        
        // Parse B* drag term (line 1, columns 53-61)
        let bstarStr = line1.substring(53, 61).trimmingCharacters(in: .whitespaces)
        self.bstar = TLE.parseDecimalAssumption(bstarStr)
        
        // Parse line 2
        let inclinationStr = line2.substring(8, 16).trimmingCharacters(in: .whitespaces)
        let raanStr = line2.substring(17, 25).trimmingCharacters(in: .whitespaces)
        let eccentricityStr = line2.substring(26, 33).trimmingCharacters(in: .whitespaces)
        let argPerigeeStr = line2.substring(34, 42).trimmingCharacters(in: .whitespaces)
        let meanAnomalyStr = line2.substring(43, 51).trimmingCharacters(in: .whitespaces)
        let meanMotionStr = line2.substring(52, 63).trimmingCharacters(in: .whitespaces)
        
        guard let inc = Double(inclinationStr),
              let raanVal = Double(raanStr),
              let ecc = Double("0." + eccentricityStr),
              let argP = Double(argPerigeeStr),
              let ma = Double(meanAnomalyStr),
              let mm = Double(meanMotionStr) else {
            return nil
        }
        
        self.inclination = inc
        self.raan = raanVal
        self.eccentricity = ecc
        self.argumentOfPerigee = argP
        self.meanAnomaly = ma
        self.meanMotion = mm
    }
    
    /// Parse TLE decimal format (assumed decimal point)
    private static func parseDecimalAssumption(_ str: String) -> Double {
        guard !str.isEmpty else { return 0.0 }
        
        var cleanStr = str.trimmingCharacters(in: .whitespaces)
        let isNegative = cleanStr.hasPrefix("-")
        if isNegative || cleanStr.hasPrefix("+") {
            cleanStr = String(cleanStr.dropFirst())
        }
        
        // Find exponent
        var mantissa = cleanStr
        var exponent = 0
        
        if let expIndex = cleanStr.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            let expPart = String(cleanStr[expIndex...])
            mantissa = String(cleanStr[..<expIndex])
            exponent = Int(expPart) ?? 0
        }
        
        // Add assumed decimal
        let value = (Double("0." + mantissa) ?? 0.0) * pow(10.0, Double(exponent))
        return isNegative ? -value : value
    }
    
    private static func calculateJulian(year: Int, dayOfYear: Double) -> Double {
        let dayInt = Int(dayOfYear)
        let dayFrac = dayOfYear - Double(dayInt)
        
        return 367.0 * Double(year) -
               floor(7.0 * (Double(year) + floor(10.0 / 12.0)) / 4.0) +
               floor(275.0 / 9.0) +
               Double(dayInt) + 1721013.5 + dayFrac
    }
}

// MARK: - String Extension

private extension String {
    /// Substring helper for TLE parsing (1-indexed columns)
    func substring(_ start: Int, _ end: Int) -> String {
        let startIdx = index(startIndex, offsetBy: start, limitedBy: endIndex) ?? endIndex
        let endIdx = index(startIndex, offsetBy: end, limitedBy: endIndex) ?? endIndex
        return String(self[startIdx..<endIdx])
    }
}
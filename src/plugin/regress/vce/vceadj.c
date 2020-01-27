ST_double gf_regress_vceadj_ols_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    ST_double Jdbl = J;
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}

ST_double gf_regress_vceadj_ols_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    ST_double Jdbl = J;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}
